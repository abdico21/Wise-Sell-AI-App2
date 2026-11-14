# WiseSell AI — Connected Agent and Channel Architecture

## Product scope
WiseSell AI is designed as one coordinated business-agent workspace, not isolated chatbots. The mobile Agent Hub exposes seven specialist roles. The current mobile screen is a roadmap/status interface; live AI execution is not enabled until backend services and credentials are deployed.

## Specialist agents
1. Business Assistant / Orchestrator — receives the user's goal, delegates to specialists, combines outputs, requests approval for consequential actions and explains results.
2. Digital Marketing Agent — campaign strategy, audience segments, channel mix, budgets, offers and measurement.
3. Content Marketing Agent — content calendars, product copy, landing-page copy, articles and localized assets.
4. SEO Agent — keyword clusters, technical/on-page audit recommendations, metadata, internal links and search performance.
5. Social Media Marketing Agent — channel-specific post variants, scheduling proposals, moderation/reply drafts and engagement reporting.
6. Video & Audio Marketing Agent — concepts, scripts, storyboards, subtitles, voice-over briefs, audio ad scripts and production handoffs. Media generation requires a configured provider.
7. Inventory Management Agent — stock summaries, reorder suggestions, low-stock alerts, product velocity and inventory-aware campaign recommendations.

## Inter-agent coordination
Specialists communicate through the Business Assistant and a backend task/event bus. Every task carries tenant/business ID, user ID, correlation ID, locale, permissions, input references, output schema and audit metadata. Agents read only authorized business data. Outputs are versioned recommendations; publishing, customer messaging, stock changes, spending or listing edits require explicit approval unless a narrowly scoped policy is configured.

Example: for “promote products with excess stock,” Inventory identifies eligible products; Marketing proposes a campaign; Content creates localized copy; SEO suggests landing-page improvements; Social adapts channel posts; Video & Audio prepares a short-video script; the Business Assistant presents one coordinated plan for approval.

## Social and video platform connections
Target channels: WhatsApp Business Platform, Telegram Bot API, Facebook Pages, Instagram professional accounts, TikTok, LinkedIn and YouTube. Use each provider's official API, OAuth/token flow, scopes, app review and account eligibility. Access differs by platform and region. Do not scrape accounts or collect passwords. Keep tokens server-side in a secrets manager; never embed them in Flutter or commit them to Git.

Build channel adapters for account connection, permission status, content validation, draft preview, publish/schedule, delivery status and analytics. Provide manual export/share when API capability is unavailable. WhatsApp messaging may require approved templates and consent; Instagram/Facebook publishing requires eligible accounts and permissions; TikTok and LinkedIn publishing depend on API product approval; YouTube upload requires OAuth and quota handling.

## Ethiopian language rollout
- English (en)
- Amharic (am)
- Afaan Oromo (om)
- Tigrinya (ti)
- Somali (so)
- Afar (aa)

The current app localization foundation exposes English, Amharic, Afaan Oromo, Tigrinya and Somali. Afar is planned, not yet shipped. Full multilingual operation also requires localized agent prompts, generated content, safety messages, speech recognition and text-to-speech. Preserve source language, allow user-selected response language and review machine-translated marketing content. Test scripts, fonts, numerals, dates and currency with native speakers.

## Suggested implementation sequence
1. Backend identity, tenant isolation, consent and permissions.
2. Business Assistant orchestration API, durable task queue, shared context store and audit log.
3. Connect sales, inventory, customer and business-profile data through read-only tools.
4. Add marketing, content, SEO, social and media agent services with typed contracts.
5. Add official OAuth/channel adapters one at a time after developer access is approved.
6. Validate Amharic, Afaan Oromo, Tigrinya, Somali and English; then implement and validate Afar.
7. Add human approval, retries, rate limits, observability, retention controls and end-to-end tests.

## Current status
The Flutter Agent Hub is a navigation and product-scope foundation. It does not mean agents are live, interconnected at runtime, generating media, translating every screen or connected to social accounts. Those capabilities require backend implementation, provider approvals, credentials and testing.