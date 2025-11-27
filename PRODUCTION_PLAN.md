# Production Readiness Plan

> Goal: Ship a stable, performant, and compliant app to Google Play. Below is a prioritized, checkbox-style plan. Check off as you complete.

## 0) Release Engineering (Required to publish)
- [ ] Create Play Console account and set up app listing (package name: confirm final)
- [ ] Generate secure keystore and configure release signing (`key.properties`)
- [ ] Configure `build.gradle` for release (minifyEnabled/shrinkResources, proguard-rules.pro)
- [ ] Switch to AAB output (`flutter build appbundle`), verify Play integrity
- [ ] App versioning policy (semantic versioning; bump code/name per release)
- [ ] Configure `compileSdk`/`targetSdk` to latest stable; verify `minSdk`
- [ ] Verify AGP/KGP/Gradle versions compatibility (upgrade Kotlin to 2.1.x, AGP to matching)
- [ ] Add privacy policy URL + in-app disclosures if needed (data, ads, analytics)
- [ ] Create internal testing track and roll out AAB for testers

## 1) UI/UX Improvements
- [ ] Topic selection: match language selection UI with checkbox tiles (same component styling)
- [ ] Reverse language selection flow: "I speak" ➜ "I want to learn"
- [ ] Expand topics (curated set + icons) and pagination/search if list grows
- [ ] Consistent spacing, colors, typography (design tokens)
- [ ] Add empty states and loading skeletons
 - [ ] Overall visual style inspired by Conjucat app look (clean, focused language-learning UI)

## 2) Quiz Experience & Pedagogy
- [ ] Memorization hints (mnemonics, example sentences, spaced repetition tips)
- [ ] Multiple modalities: 
  - [ ] Multiple choice
  - [ ] Type-the-answer
  - [ ] Listening (TTS)
  - [ ] Translating from native language into target language
  - [ ] Flashcards / review mode
- [ ] Hints (eliminate options, reveal first letter, show example)
- [ ] Difficulty scaling and adaptive selection (based on user accuracy)
- [ ] Session summaries with actionable feedback
 - [ ] Audio pronunciation inside quizzes (play question/answer audio via TTS or recordings)

## 3) Stats, Progression, and Leaderboard
- [ ] Detailed stats: accuracy per topic, streaks, time per question
- [ ] Progress graphs (weekly, monthly), topic mastery heatmap
- [ ] XP leveling system with tiers and badges
- [ ] Leaderboard (global/friends) with anti-cheat basics
 - [ ] IMPORTANT: Vocabulary ranking with a scoring system for pronunciation quality, use in context, and grammar accuracy

## 4) Localization & Internationalization
- [ ] Localize all app strings via `flutter_localizations`/`intl`
- [ ] Auto-apply locale per device settings; allow manual override
- [ ] RTL layout support verification
- [ ] Localize store listing

## 5) Monetization
- [ ] Ads: integrate Google Mobile Ads SDK (non-invasive placements)
  - [ ] Consent flow (GDPR/CCPA) via UMP SDK
  - [ ] Mediation testing, frequency caps, no interstitials on critical flows
- [ ] IAP: subscriptions or one-time unlock (remove ads, unlock modes)
  - [ ] Free trial handling, restore purchases

## 6) Backend (Supabase, no JSON files)
- [ ] Design data model: users, vocabulary, topics, progress, sessions, leaderboards
- [ ] Set up Supabase project, tables, RLS policies
- [ ] Auth: email/password + social (optional)
- [ ] CRUD for vocabulary and topic metadata
- [ ] Sync user progress (XP, mastery per word, history)
- [ ] Server functions for leaderboards and anti-abuse checks
- [ ] Migrate existing local JSON import flow to Supabase fetch + offline cache

## 7) Data, Privacy, and Compliance
- [ ] Document data collection and retention
- [ ] In-app privacy disclosures + link to policy
- [ ] Crash reporting and analytics with opt-out
- [ ] Ensure COPPA/age gating if targeting children (likely not)

## 8) Analytics & Observability
- [ ] Integrate Firebase Analytics + Crashlytics
- [ ] Define events: session start, quiz start/complete, hint used, topic selected, ad impression, purchase
- [ ] Dashboards for conversion funnels (onboarding ➜ first quiz ➜ retention)

## 9) Performance & Quality
- [ ] Optimize build size (R8 shrinking, remove unused assets, tree-shake icons)
- [ ] Smooth animations (60fps target), list virtualization
- [ ] Memory leaks audit, profile on low-end devices
- [ ] Network resilience, offline-first (cache, retry)

## 10) Testing Strategy
- [ ] Unit tests: services (vocabulary, quiz logic, stats)
- [ ] Widget tests: UI components (topic tiles, answer options)
- [ ] Golden tests for key screens
- [ ] Integration tests (`integration_test`) for full quiz flow
- [ ] Smoke tests for release AAB
- [ ] CI to run tests on PRs

## 11) CI/CD
- [ ] Set up GitHub Actions: format, analyze, test, build
- [ ] Fastlane for version bump + Play Store upload
- [ ] Internal, closed, open test tracks automation

## 12) Security & Safety
- [ ] Keystore management and secret storage
- [ ] Pin dependencies; run `flutter analyze` and security scans
- [ ] Basic input validation (type-in answers)
- [ ] Abuse prevention for leaderboards

## 13) Accessibility
- [ ] Screen reader labels, large text support
- [ ] Color contrast, focus order, tap targets
- [ ] Haptics/feedback options

## 14) Store Readiness
- [ ] App icons, adaptive icons, feature graphic, screenshots (localized)
- [ ] Short & long description (ASO keywords)
- [ ] Content rating questionnaire
- [ ] Target audience and ads declarations
- [ ] Release notes template

---

# Implementation Details per Your Requests

## Topic Selection UI (match language selection)
- [ ] Extract checkbox tile component from language selection
- [ ] Reuse styles for topic items (emoji/icon, title, subtitle)
- [ ] Multi-select state, count indicator, clear-all

## Reverse Language Selection Flow
- [ ] Screen 1: "I speak" (source)
- [ ] Screen 2: "I want to learn" (target)
- [ ] Persist pair; migrate existing prefs key if needed

## More Topics
- [ ] Curate list: food, family, work, travel, nature, emotions, hobbies, tech, numbers, colors, time, shopping
- [ ] Icons/emojis and descriptions
- [ ] Lazy load/paginate if >20 topics

## Better Stats & Graphs
- [ ] Add per-topic accuracy, average time/question
- [ ] Streaks and calendar heatmap
- [ ] Charts (sparkline/line/bar) with `charts_flutter` or `fl_chart`

## Memorization Hints
- [ ] Mnemonics and example sentences per word (from Supabase)
- [ ] SRS (spaced repetition) weights
- [ ] Hint economy (limited hints per session)

## Modalities & Hints
- [ ] Add type-the-answer mode, translating from native language into target language, and listening mode (TTS via `flutter_tts`)
- [ ] Hints: 50/50, reveal letter, show example

## Audio Controls
- [ ] User-adjustable speaking/listening velocity (TTS rate slider/buttons) for quizzes, listening mode, and stories

## Localization
- [ ] Intl setup, ARB files, extract strings
- [ ] Device-locale default + in-app switch

## Payments & Ads
- [ ] Google Mobile Ads (banner/native), frequency caps
- [ ] In-app purchases (remove ads, premium features)
- [ ] Consent (UMP), policy-compliant placements

## Supabase Integration
- [ ] Schema for words/topics/users/progress
- [ ] RLS policies for user isolation
- [ ] Sync engine: pull on start, delta updates, cache

## Tests
- [ ] Minimum coverage thresholds
- [ ] E2E flows for onboarding ➜ quiz ➜ results

## Leaderboard
- [ ] Public leaderboard with pagination
- [ ] Friends leaderboard (optional: OAuth or invite codes)
- [ ] Validation on server to prevent spoofing

## Teacher Tools
- [ ] Teacher tooling to create graded readers from existing texts based on lemma lists (500/1000/1500+ words), with optional controls for allowed tenses and grammar structures

---

# Milestones & Order of Execution

## M1: Foundation & Release Setup (1–2 weeks)
- [ ] Versioning, signing, AGP/KGP upgrades, AAB builds
- [ ] Crashlytics/Analytics, privacy policy
- [ ] CI for build/test

## M2: UX & Core Features (2–3 weeks)
- [ ] Topic UI parity with language UI
- [ ] Reverse language selection flow
- [ ] More topics, improved quiz modes, hints
- [ ] Stats page V1

## M3: Backend & Monetization (2–4 weeks)
- [ ] Supabase integration (vocabulary + progress)
- [ ] Leaderboard
- [ ] Ads + IAP

## M4: Polish, Localization, Accessibility (1–2 weeks)
- [ ] Localization pass
- [ ] Accessibility improvements
- [ ] Performance profiling and size optimization

## M5: Store Readiness & Launch (1 week)
- [ ] Store listing assets
- [ ] Internal testing ➜ closed ➜ production rollout

---

# Technical Debt & Cleanup
- [ ] Stabilize Kotlin version (2.1.x) and AGP alignment
- [ ] Remove legacy JSON import once Supabase is live
- [ ] Refactor services to repository pattern
- [ ] Add logging and error boundaries
- [ ] Fix error where only one answer is shown in questions in My List quiz
 - [ ] Fix Ruzzle behavior for Russian (grid/word generation and UX)

---

# Nice-to-Have Ideas
- [ ] Daily goals and reminders
- [ ] Achievements and seasonal events
- [ ] Downloadable language packs for offline
- [ ] Social sharing of achievements
- [ ] A/B tests on onboarding and hint funnels
- [ ] Tooling to generate accurate subtitles for obscure/native media the user enjoys
- [ ] Gamified writing streaks with incentives to correct other learners' writing
- [ ] AI-generated gradual readers (Natural Method style) that adapt difficulty based on known vocabulary/grammar and repeat items on a personalized schedule
- [ ] Ability to flag/mark words while reading or in quizzes for later focused study (LingQ-style "lingqs")
- [ ] A "My vocabulary" view listing all learned words with strength indicators and filters to see which items need more work (Memrise-style)
- [ ] Per-word detail view: tap any word to see its gender (for nouns), full conjugation/paradigm, and example sentences using that word in context
- [ ] A fully conversational + narrative story mode (Duolingo-style stories / La lingua naturale) where a continuous story builds on itself with integrated audio for all text
- [ ] Story library filters: browse stories by estimated time/length, topic, level, and other attributes
- [ ] Optional IPA view for words: show phonetic transcription alongside audio/pronunciation details for learners who want it
- [ ] Guided journaling exercises: daily/weekly prompts with feedback on vocabulary, grammar, and style
- [ ] Reading exercises with color-coding/highlighting (e.g. new vs learning vs known vocabulary)
 - [ ] AI-powered chatting mode for free-form conversation practice with corrective feedback
 - [ ] Community-based pronunciation feedback, where learners can submit recordings and receive peer or tutor ratings (Busuu-style)
