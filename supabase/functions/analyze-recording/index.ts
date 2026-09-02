import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const jsonResponse = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  let stage = "initialization";
  try {
    const authorization = request.headers.get("Authorization");
    if (!authorization?.startsWith("Bearer ")) return jsonResponse({ error: "Authentication is required.", stage }, 401);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const openAiKey = Deno.env.get("OPENAI_API_KEY");
    if (!supabaseUrl || !anonKey || !serviceRoleKey) return jsonResponse({ error: "Supabase server configuration is incomplete.", stage }, 500);
    if (!openAiKey) return jsonResponse({ error: "OPENAI_API_KEY is missing.", stage }, 500);

    stage = "authentication";
    const token = authorization.replace("Bearer ", "");
    const authClient = createClient(supabaseUrl, anonKey);
    const { data: { user }, error: authError } = await authClient.auth.getUser(token);
    if (authError || !user) return jsonResponse({ error: "Invalid authentication token.", stage }, 401);

    stage = "request-validation";
    const body = await request.json();
    const storagePath = String(body.storagePath ?? "");
    const exerciseId = String(body.exerciseId ?? "");
    const exerciseTitle = String(body.exerciseTitle ?? "");
    const exerciseContext = String(body.exerciseContext ?? "");
    const duration = Math.max(0, Number(body.recordingDurationSeconds ?? 0));
    if (!storagePath || !exerciseId) return jsonResponse({ error: "storagePath and exerciseId are required.", stage }, 400);
    if (!storagePath.startsWith(`recordings/${user.id}/`)) return jsonResponse({ error: "Recording does not belong to this user.", stage }, 403);

    stage = "storage-download";
    const admin = createClient(supabaseUrl, serviceRoleKey);
    const { data: recording, error: downloadError } = await admin.storage.from("speech-recordings").download(storagePath);
    if (downloadError || !recording) return jsonResponse({ error: downloadError?.message ?? "Could not read the uploaded recording.", stage }, 400);

    stage = "openai-transcription";
    const form = new FormData();
    form.append("file", recording, "recording.m4a");
    form.append("model", "whisper-1");
    form.append("response_format", "verbose_json");
    const transcriptResponse = await fetch("https://api.openai.com/v1/audio/transcriptions", {
      method: "POST",
      headers: { Authorization: `Bearer ${openAiKey}` },
      body: form,
    });
    if (!transcriptResponse.ok) return jsonResponse({ error: await transcriptResponse.text(), stage }, 502);
    const transcription = await transcriptResponse.json();
    const transcript = String(transcription.text ?? "").trim();
    const words = transcript ? transcript.split(/\s+/).filter(Boolean) : [];
    const pace = duration > 0 ? Math.round((words.length / duration) * 600) / 10 : 0;
    const hesitations = (transcript.match(/\b(um+|uh+|er+|erm|you know|like)\b/gi) ?? []).length;
    const pauses = Math.max(0, Math.round(duration / 8) - 1);

    stage = "openai-feedback";
    const feedbackResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: { Authorization: `Bearer ${openAiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        temperature: 0.3,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: "You are a supportive speech-practice coach. Never diagnose or shame the learner." },
          { role: "user", content: `Return JSON with fluency (excellent, good, developing, or needs_practice) and feedback (one short encouraging sentence). Pace: ${pace} WPM. Pauses: ${pauses}. Hesitations: ${hesitations}. Exercise: ${exerciseTitle}. Context: ${exerciseContext}. Transcript: ${transcript}` },
        ],
      }),
    });
    if (!feedbackResponse.ok) return jsonResponse({ error: await feedbackResponse.text(), stage }, 502);
    const feedbackPayload = await feedbackResponse.json();
    const analysis = JSON.parse(feedbackPayload.choices?.[0]?.message?.content ?? "{}");
    const fluency = String(analysis.fluency ?? "developing");
    const feedback = String(analysis.feedback ?? "Nice work practicing today!");

    stage = "database-save";
    const { error: saveError } = await admin.from("speech_analyses").insert({
      user_id: user.id,
      exercise_id: exerciseId,
      storage_path: storagePath,
      transcript,
      speaking_duration_seconds: duration,
      speaking_pace_wpm: pace,
      pause_count: pauses,
      hesitation_count: hesitations,
      fluency,
      feedback,
    });
    if (saveError) return jsonResponse({ error: saveError.message, stage }, 500);

    return jsonResponse({ transcript, feedback, speakingDurationSeconds: duration, speakingPaceWpm: pace, pauseCount: pauses, hesitationCount: hesitations, fluency });
  } catch (error) {
    console.error(`analyze-recording ${stage}`, error);
    return jsonResponse({ error: String(error), stage }, 500);
  }
});
