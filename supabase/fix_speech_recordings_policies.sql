drop policy if exists "Users can upload their own recordings" on storage.objects;
drop policy if exists "Users can read their own recordings" on storage.objects;

create policy "Users can upload their own recordings"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'speech-recordings'
  and name like ('recordings/' || auth.uid()::text || '/%')
);

create policy "Users can read their own recordings"
on storage.objects for select
to authenticated
using (
  bucket_id = 'speech-recordings'
  and name like ('recordings/' || auth.uid()::text || '/%')
);

update storage.buckets
set public = false
where id = 'speech-recordings';
