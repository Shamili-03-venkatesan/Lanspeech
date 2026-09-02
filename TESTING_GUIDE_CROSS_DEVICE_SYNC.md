## TESTING GUIDE: Cross-Device Progress Sync

### Prerequisites
1. Supabase project is running and configured in `config/.env`
2. You have the migration SQL file ready: `supabase/setup_user_progress_tables.sql`
3. Two devices/emulators available (can be same machine with different emulator instances)

---

## STEP 1: Set Up Supabase Tables

### In Supabase Dashboard:

1. Go to SQL Editor in your Supabase project
2. Copy the entire contents of `supabase/setup_user_progress_tables.sql`
3. Paste into a new SQL query
4. Click "Run" to execute

**What it creates:**
- `user_exercise_progress` table with RLS
- `user_gamification` table with RLS
- `user_practice_activity` table with RLS
- Proper indexes and security policies

**Verify success:** You should see all three tables under "Tables" in Supabase Dashboard

---

## STEP 2: Build and Deploy App

```bash
flutter clean
flutter pub get
flutter run  # on Phone 1 / Emulator 1
```

Wait for the app to fully load and initialize.

---

## STEP 3: Test Scenario - Cross-Device Sync

### PHONE 1 (or Emulator 1)

#### Step 3a: Register / Login
- **Option A**: Create a new account
  - Email: `testuser@example.com`
  - Password: `Test123!`
- **Option B**: Use an existing test account

#### Step 3b: Complete Onboarding
- Go through the onboarding flow (if not completed)
- Click "Dashboard" to reach the home screen

#### Step 3c: Complete Exercises (Multiple)
- Click "Practice" or "Start Practice" / "Continue Your Practice"
- Go to Chapter 1, Exercise 1
- Click "Record" and try recording (can be silent, just needs duration)
- Click "Submit" or "Continue"
- Wait for AI analysis to complete (or skip if not available)
- You should see: ✅ Exercise marked as complete
- **IMPORTANT**: Check these screens for confirmation:
  - Dashboard → "Progress Summary Row" shows updated count (e.g., "1 / 12" → "2 / 12")
  - Profile tab → "Completed Exercises" count increases
  - Profile tab → "Total XP" increases (should add 10 XP per exercise)
  - Profile tab → "Current Streak" = 1
- **Repeat for 3-5 exercises** to build up data

#### Step 3d: Verify Data is Visible
- Go to **Profile tab**
  - ✅ XP counter shows (e.g., 30, 40, 50)
  - ✅ Streak shows 1 (or today's count)
  - ✅ Total exercises completed shows (3, 4, 5)
  - ✅ Practice calendar/dates show today's date
  - ✅ Recording time shows (in minutes)

#### Step 3e: Verify Data in Supabase (Optional but Recommended)
- Open Supabase Dashboard
- Go to **user_exercise_progress** table
  - Filter by `user_id` = your logged-in user's ID
  - ✅ Should see 3-5 rows (one per completed exercise)
  - ✅ Each row has `exercise_id`, `completed_at` timestamp

- Go to **user_gamification** table
  - Filter by `user_id`
  - ✅ Should see 1 row with:
    - `total_xp`: 30, 40, or 50 (10 per exercise)
    - `current_streak`: 1
    - `longest_streak`: 1
    - `practiced_dates`: ["2024-XX-XX"] (today's date)

- Go to **user_practice_activity** table
  - Filter by `user_id`
  - ✅ Should see 1 row with:
    - `session_count`: 3-5 (one per exercise)
    - `total_recorded_seconds`: > 0
    - `practice_dates`: ["2024-XX-XX"]

#### Step 3f: Close the App on Phone 1
- Press home button or swipe up (don't force close, let it close gracefully)
- Wait 5 seconds

---

### PHONE 2 (or Emulator 2) — THE CRITICAL TEST

#### Step 4a: Install/Build App on Phone 2
```bash
flutter run -d <device-2-id>  # If using multiple emulators
# Or just run on a second physical phone
```

Wait for app to fully load

#### Step 4b: Login with Same Email
- Click "Login" (or if splash screen, wait for redirect)
- Enter: `testuser@example.com` (SAME email as Phone 1)
- Enter password: `Test123!`
- Click "Login"
- Wait for auth to complete and app to load

#### Step 4c: THE CRITICAL CHECK - Verify Progress Synced
- ✅ **Go to Dashboard or Profile**
  - **XP counter should show 30-50** (NOT 0)
  - **Streak should show 1** (NOT 0)
  - **Completed exercises count should match Phone 1** (NOT 0)
  - **Practice dates/calendar should show today's date**
  - **Total recording time should match Phone 1**

**IF ALL THE ABOVE MATCH PHONE 1, THE SYNC IS WORKING! ✅**

#### Step 4d: Navigate Through UI to Verify
- Click "Curriculum" or "Practice"
  - ✅ Should show same progress (e.g., "3 / 12 exercises" not "0 / 12")
  - ✅ First incomplete exercise should be the one after Phone 1's last
  - ✅ Completed exercises should be marked/grayed out/have checkmarks

- Click "Progress" tab
  - ✅ Should show same progress graphs/stats as Phone 1

- Click "Profile" tab
  - ✅ All gamification stats should match exactly

---

### OPTIONAL ADVANCED TEST: Multi-Device Sync

#### Step 5: Complete More Exercises on Phone 2
- Go back to Practice
- Complete 2-3 MORE exercises on Phone 2
- Verify XP, streak, count all increase

#### Step 6: Check Phone 1
- Switch back to Phone 1 or reopen app
- ✅ **XP should now be HIGHER** (Phone 1's original + Phone 2's new)
- ✅ **Exercise count should be higher**
- ✅ **These stats prove bi-directional sync**

---

## TESTING CHECKLIST

### Critical (Must Pass)
- [ ] Phone 1: Complete 3-5 exercises
- [ ] Phone 1: XP, Streak, Exercise count visible and > 0
- [ ] Supabase tables have data (optional but recommended)
- [ ] Phone 2: Login with same email
- [ ] Phone 2: All stats match Phone 1 exactly
- [ ] No errors in device console

### Important (Should Pass)
- [ ] Completed exercises show as completed on Phone 2
- [ ] First incomplete exercise is correct on Phone 2
- [ ] Practice calendar shows same dates on both phones
- [ ] Total recording time matches

### Nice to Have (Optional)
- [ ] Bi-directional sync works (complete exercises on Phone 2, check on Phone 1)
- [ ] Offline functionality (disable internet, make local changes, then sync)
- [ ] App restart doesn't reset progress

---

## TROUBLESHOOTING

### Problem: Phone 2 shows 0 XP / 0 exercises
**Solution:**
1. Check Supabase tables have data (see Step 3e above)
2. Verify user is authenticated (check if logged-in name shows)
3. Check app console for error messages
4. Verify RLS policies are correct (all allow `auth.uid()` access)

### Problem: "Users can only read their own..." error
**Solution:**
- RLS policies are working (good!) but user ID might be wrong
- Ensure you're logged in with the same email on both devices
- Check Supabase auth that both logins created the same `user_id`

### Problem: Data not syncing from Phone 1 to cloud
**Solution:**
1. Check internet connection
2. Check Firebase/Supabase connection in the app
3. Look for error messages in console
4. Verify Supabase URL in `config/.env` is correct

### Problem: Supabase SQL error when running setup
**Solution:**
1. Make sure tables don't already exist
2. Drop tables if needed: `DROP TABLE IF EXISTS user_exercise_progress, user_gamification, user_practice_activity CASCADE;`
3. Run the SQL again

---

## WHAT EACH PROVIDER DOES NOW

### CurriculumProgressNotifier
```
On init:
1. Try to fetch completed exercises from Supabase
2. If cloud has data, use it and update local cache
3. If cloud is empty, load from local cache
4. If local data exists and cloud is empty, sync local to cloud

On exercise completion:
1. Update local state
2. Update local cache (SharedPreferences)
3. Sync to Supabase (async, background)
```

### GamificationNotifier
```
On init:
1. Fetch XP, streaks, dates from Supabase
2. If cloud has data, use it and update local cache
3. If cloud is empty, load from local cache
4. If local data exists and cloud is empty, sync local to cloud

On exercise completion (recordExerciseCompletion):
1. Update XP
2. Update practice calendar
3. Recalculate streaks
4. Update state
5. Save to local cache
6. Sync to Supabase
```

### PracticeActivityNotifier
```
On init:
1. Fetch recording time, session count from Supabase
2. If cloud has data, use it and update local cache
3. If cloud is empty, load from local cache
4. If local data exists and cloud is empty, sync local to cloud

On session record (recordSession):
1. Add session to activity
2. Update total recording time
3. Update session count
4. Update today's recording time
5. Save to local cache
6. Sync to Supabase
```

---

## OFFLINE BEHAVIOR

When internet is offline:
- ✅ App still works (uses local cache)
- ✅ New exercises can be completed (saved to local cache)
- ✅ XP and streak still update locally
- ✅ When internet returns, changes sync to Supabase
- ✅ If user switches devices while offline, they'll get cloud data when they log in

---

## SUCCESS CRITERIA

You'll know it's working when:
1. ✅ Phone 1 has progress
2. ✅ Phone 2 (same account) shows exact same progress
3. ✅ No "permission denied" errors (RLS is working)
4. ✅ Console shows no errors
5. ✅ Supabase tables have data matching the UI
