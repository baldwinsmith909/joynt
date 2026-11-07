# Joynt

Public TikTok-style meal feed for iPhone. Photo + optional short note. Soft interactions only — appreciate, save, comment, follow. **No ratings, stars, or review prompts.**

Visual system follows [apm.shopify.com](https://apm.shopify.com): cream ground, heavy type, thick black frames, hard shadows, sticky notes, black pills with color offset.

## Stack

- Native SwiftUI (iOS 17+)
- Sign in with Apple
- Supabase (Auth, Postgres, Storage)

## Open the project

```bash
cd ~/Desktop/joynts
xcodegen generate
open Joynt.xcodeproj
```

Or build from the CLI:

```bash
xcodegen generate
xcodebuild -scheme Joynt -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Demo mode (no credentials)

Launch the app and tap **Continue with demo meals**. You get seeded posters, For You / Following feeds, appreciate / save / comments, follow/unfollow, and the composer — all offline.

## Production setup

### 1. Supabase

1. Create a project at [supabase.com](https://supabase.com).
2. Run `supabase/migrations/001_initial.sql` in the SQL editor.
3. Authentication → Providers → enable **Apple**.
4. Copy Project URL + `anon` key into `Joynt/Config/SupabaseConfig.swift`.

### 2. Apple Developer

1. Create an App ID with **Sign in with Apple**.
2. Create a Services ID / key for Supabase Apple auth (follow Supabase’s Apple guide).
3. In Xcode, set your **Team** on the Joynt target and confirm the bundle id `com.joynt.app` (or change it).

### 3. What Baldwin still needs to provide

| Item | Where |
|------|--------|
| Supabase URL + anon key | `Joynt/Config/SupabaseConfig.swift` |
| Apple Developer Team ID | Xcode signing |
| Apple Sign In client config for Supabase | Supabase dashboard |

Until those are set, use demo mode.

## Product rules (do not break)

- Posts = one photo + optional note (≤140 chars). Note may be blank.
- Feeds: **For You** (ranked from follows + appreciate/save/comment/dwell) and **Following** (chrono).
- Ranking score is never shown.
- No stars, recommend prompts, or review templates.
- Public counts stay quiet.

## Layout

```
Joynt/                 SwiftUI app
supabase/migrations/   Postgres + storage policies
project.yml            XcodeGen spec
Scripts/               Capture helpers
```
