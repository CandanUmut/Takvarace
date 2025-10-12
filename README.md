# Takva (Niyet) – Privacy-First Good Deeds Tracker

Takva is a bilingual (English + Türkçe) Flutter Web progressive web app for tracking good deeds without exposing private details. Only an anonymous alias and weekly aggregate score are synced to Supabase; every other detail remains encrypted on the device.

## Philosophy

* **Zero exposure:** Detailed deeds, diary, repentance notes, and triggers never leave the browser. Only weekly totals are uploaded.
* **Tövbe beats riya:** Repentance flows reward coming back more than perfection.
* **Community without vanity:** Public leaderboards show only aliases + weekly scores and can be disabled at any time.
* **Digital shields:** Built-in guides to configure Screen Time / Digital Wellbeing tools.

## Tech Stack

| Layer | Choice |
| --- | --- |
| Frontend | Flutter (stable channel) with Riverpod, go_router, intl |
| Storage | `flutter_secure_storage` + AES encryption (web-friendly) |
| Backend | Supabase (Auth + Postgres) – only alias + weekly score |
| Hosting | GitHub Pages (static) |
| Localization | Custom loader for `.arb` files (EN/TR) |

## Project Structure

```
lib/
  app.dart
  main.dart
  l10n/
  core/
  data/
  domain/
  features/
  theme/
assets/config/points.{en,tr}.json
supabase/schema.sql
.github/workflows/deploy.yml
seed/mock_local_export.json
```

## Getting Started

1. **Install Flutter** (3.16+ recommended).
2. **Fetch dependencies**
   ```bash
   flutter pub get
   ```
3. **Run locally**
   ```bash
   flutter run -d chrome \
     --dart-define=SUPABASE_URL=http://localhost \
     --dart-define=SUPABASE_ANON_KEY=stub
   ```
   *Without Supabase credentials the app falls back to offline mode (scores stay local).* 

## Supabase Setup

1. Create a Supabase project and enable anonymous auth.
2. Apply SQL from [`supabase/schema.sql`](supabase/schema.sql) using the Supabase SQL editor.
3. In **Authentication → Providers**, enable *Email (magic link)* if you need upgrades. Anonymous auth is sufficient for MVP.
4. In **Project Settings → API**, copy the `project URL` and `anon public key`.
5. Configure Redirect URLs (if using magic links): `https://<username>.github.io/Takvarace/`.
6. Populate GitHub repository secrets:
   * `SUPABASE_URL`
   * `SUPABASE_ANON_KEY`

## GitHub Pages Deployment

1. Ensure the repo default branch is `main`.
2. Push changes. GitHub Actions workflow [`deploy.yml`](.github/workflows/deploy.yml) will:
   * Install Flutter (stable)
   * Build the web bundle with Supabase environment variables
   * Publish `build/web` to the `gh-pages` branch via `peaceiris/actions-gh-pages`
3. In repo settings enable **Pages** → Source: `Deploy from a branch`, Branch: `gh-pages`.
4. Access the app at `https://<username>.github.io/Takvarace/`.

## Environment & Secrets

* Runtime env uses Dart defines: `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
* Development helpers:
  * `.env.sample` for local reference
  * `seed/mock_local_export.json` to pre-populate local encrypted data (import via Diary → Import)

## Features Overview

* **Onboarding**: pick language, choose anonymous alias (3–24 chars), toggle leaderboard sharing.
* **Dashboard**:
  * Clean timer card showing seconds since last fall (persisted locally).
  * Quick action buttons for common deeds (farz, dhikr, Qur’an, repentance shortcut).
  * Regex-based parser for free-text logs (EN/TR patterns).
  * Repentance flow modal (3 steps) applying weekly multipliers + recovery bonus.
* **Diary**: encrypted reflections with import/export clipboard flow.
* **Leaderboard**: optional weekly standings; hidden if user disables sharing.
* **Shields**: digital wellbeing checklists for iOS/Android/browser.
* **Settings**: language switch, share toggle, private mode (local only).

## Regex “Light AI”

`ParserService` uses language-specific regular expressions (`parser_service.dart`) mapped to the configurable points catalog in `assets/config/points.*.json`. Extend the JSON file to add new deed profiles without changing code.

## Limitations

* Flutter web secure storage relies on browser capabilities; clearing site data wipes encrypted vaults.
* No native push notifications or background timers in web build.
* Leaderboard assumes Supabase RLS policies configured exactly as provided.
* Offline mode skips Supabase entirely—scores sync once credentials are injected and the session is anonymous.

## Future Enhancements

* Breathwork timer widget for urgent nafs attacks.
* Native builds (iOS/Android) for notifications and deeper OS integrations.
* Community-configurable points packs loaded from remote encrypted bundles.

## License

MIT – see repository for details.
