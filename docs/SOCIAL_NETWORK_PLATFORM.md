# Wise Sell AI — Social Network Platform Specification

## Product direction
Extend the existing Wise Sell AI product into an independent business and social networking platform, while retaining the existing AI business assistant backend, Firebase project, Cloudflare Worker, and current app identity.

Firebase project: `gen-lang-client-0645056984`
Existing Worker service: `wise-sell-ai-app2`
Existing Worker base URL: `https://wise-sell-ai-app2.abdico-veiws22.workers.dev`

This document defines the target scope. It does not claim that these social features are already implemented.

## Core first-party social network
1. User identity and profiles: avatar, display name, username, bio, location (optional), business identity (optional), follower/following lists, privacy controls, profile verification state.
2. Home feed: text, image, video, link and product posts; chronological feed initially; likes/reactions, comments, shares, saves, report and block controls.
3. Stories and short videos: time-limited stories, vertical video feed, creator profile, captions, reactions, comments and view counts. Video upload/transcoding/streaming require a configured media service.
4. Messaging: one-to-one and group conversations, text, image/video/file attachments, read receipts, typing indicators, push notifications and block/report controls. Voice/video calling is a later phase requiring a real-time communications provider.
5. Communities: public/private groups, membership, posts, moderation roles, invitations and community search.
6. Business pages: organization profile, products/services, contact links, business posts, page roles, insights and customer enquiries.
7. Marketplace: seller storefronts, product listings, search, categories, availability, buyer-seller conversations and order records. Payments must remain pending until a payment provider confirms them.
8. Notifications: follows, reactions, comments, mentions, messages, group activity and moderation notices.
9. Search and discovery: users, businesses, posts, products, communities and hashtags.
10. Safety and moderation: user reporting, blocking, content visibility, rate limits, admin review queue, audit events and abuse prevention.

## External platform connections
Provide an integrations page for WhatsApp, Telegram, Facebook, Instagram, TikTok, X (Twitter), LinkedIn and YouTube. Each integration must use the platform's official supported API/OAuth flow and clearly show connection state, granted permissions and token expiry/revocation. Do not collect platform passwords. Do not promise inbox sync, publishing, analytics or account actions unless the relevant official API permission is approved and the capability is actually implemented. WhatsApp/Telegram messaging integrations are separate from Wise Sell AI's own in-app direct messaging.

## AI agents
Retain the six existing Worker agent IDs:
- `business-assistant`
- `sales-agent`
- `digital-marketing`
- `seo-content`
- `social-media`
- `video-audio`

AI-generated posts, captions, scripts and replies are drafts until the user reviews and confirms an external action. Agents must not claim to have published content or sent messages without verified provider responses.

## Firebase data model (proposed)
Use authenticated user ownership and server-side authorization. Suggested collections:
- `users/{uid}`
- `usernames/{username}`
- `follows/{followId}`
- `posts/{postId}`
- `posts/{postId}/comments/{commentId}`
- `posts/{postId}/reactions/{uid}`
- `stories/{storyId}`
- `conversations/{conversationId}`
- `conversations/{conversationId}/messages/{messageId}`
- `groups/{groupId}`
- `groups/{groupId}/members/{uid}`
- `businessPages/{pageId}`
- `businessPages/{pageId}/members/{uid}`
- `products/{productId}`
- `orders/{orderId}`
- `notifications/{uid}/items/{notificationId}`
- `reports/{reportId}`
- `integrations/{uid}/{provider}`

These are proposed names only; inspect existing Firestore collections and security rules before applying any schema or migration. Preserve all existing user data. Enforce membership, ownership, privacy and moderation rules in Firestore Security Rules and trusted backend code; never rely on client-side checks alone.

## Proposed API groups
All protected routes require a verified Firebase ID token. The Worker must derive the user ID from the verified token, never from a client-supplied uid.
- `GET/POST /api/social/posts`
- `GET /api/social/feed`
- `POST /api/social/posts/:postId/reactions`
- `GET/POST /api/social/posts/:postId/comments`
- `POST /api/social/users/:uid/follow`
- `GET/POST /api/social/conversations`
- `GET/POST /api/social/conversations/:id/messages`
- `GET/POST /api/social/groups`
- `POST /api/social/groups/:id/members`
- `GET/POST /api/social/business-pages`
- `GET/POST /api/social/products`
- `GET /api/social/search`
- `GET/POST /api/social/integrations/:provider/connect`
- `POST /api/social/reports`

These routes are a target API contract, not existing live endpoints.

## Delivery sequence
### Phase 1 — safe foundation
- Inspect the existing Android/web client source, Firebase collections, Firestore rules and Worker deployment.
- Keep Firebase project ID, Android application ID and existing user data unchanged.
- Add profile, username, follow graph and basic text/image posts.
- Add a feed, reactions, comments, search, block/report and moderation controls.
- Add automated tests for ownership and privacy rules.

### Phase 2 — communities and business network
- Add groups, business pages, product listings and buyer-seller enquiries.
- Add notifications and pagination.
- Add admin moderation and audit events.

### Phase 3 — messaging and media
- Add real-time chat and group chat.
- Add image/video uploads with validated file types, size limits and media storage.
- Add stories and short-video feed after storage and delivery infrastructure is selected.
- Add push notifications; treat calling as a separate later integration.

### Phase 4 — external integrations
- Add official OAuth/API integrations one provider at a time.
- Display provider capability and permission limitations accurately.
- Encrypt tokens server-side, implement revocation and never expose secrets to clients.

## Release acceptance criteria
- Existing sign-in, account IDs and business data remain intact.
- Users can create and edit profiles and control visibility.
- Users can create posts and interact with the feed.
- Follow, block, report and moderation paths work.
- Users cannot read or modify another user's private records without authorization.
- Messaging and media features are tested on real Android devices.
- Each external integration has a verified provider response and approved permissions before being marked connected.
- A release APK is generated from the actual Android source and installed/tested on a device.

## Current repository evidence and limitation
The repository currently contains the Cloudflare Worker at `src/index.js`, `wrangler.toml`, `README.md` and the AI agent specification. The checked repository paths did not expose a native Flutter Android project (for example `pubspec.yaml` and `lib/main.dart`). The existing APK is a compiled artifact and cannot substitute for editable source. Therefore this specification is ready for implementation, but a new Android APK cannot truthfully be claimed until the mobile source project is located and built.
