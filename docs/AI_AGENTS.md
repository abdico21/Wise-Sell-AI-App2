# Wise Sell AI — Six Agent Feature Specification

## Shared agent experience
The home screen should show six agent cards with a clear purpose, short description, and an **Open agent** action. Each agent should have a dedicated conversation/workspace, retain relevant business context only with user consent, and show useful suggested tasks. AI requests must go through an authenticated server endpoint. The mobile app must not contain an OpenAI secret key.

## 1. AI Business Manager
- Answer questions about business operations and recorded business activity.
- Create and organize tasks, reminders, and operating checklists.
- Summarize business status from data the user is authorized to access.
- Ask for missing details before creating or changing records.

## 2. AI Sales & Marketing
- Generate product descriptions, sales messages, and campaign plans.
- Draft content for Facebook, Instagram, TikTok, Telegram, WhatsApp, LinkedIn, and X.
- Suggest audience, offer, and content-calendar ideas.
- Require user review before publishing or sending content.

## 3. Marketplace Agent
- Search and filter product listings.
- Help sellers prepare listings with titles, descriptions, and categories.
- Help buyers compare available listings and contact sellers.
- Protect seller and buyer contact information; do not fabricate stock or prices.

## 4. Payments & Orders Agent
- Create and track order records and invoice drafts.
- Display payment status returned by the connected payment provider/backend.
- Provide order summaries, receipts, and status notifications.
- Never claim a payment succeeded without a verified provider confirmation. Do not store card or bank credentials in the app.

## 5. Business Intelligence Agent
- Show sales, orders, revenue, expenses, and customer KPIs from connected records.
- Compare selected date ranges and identify trends.
- Generate plain-language reports and exportable summaries.
- Clearly label estimates and forecasts; do not present them as actual results.

## 6. Enterprise Services Agent
- Guide users through business support and service requests.
- Capture partnership, supplier, and enterprise inquiry details.
- Provide onboarding checklists and request status.
- Route requests to an authorized human or service team when needed.

## App branding and compatibility
- User-facing app name: **Wise Sell AI**.
- Preserve the current Android application ID/package name, Firebase project ID, and Firebase configuration during the display-name change. A package rename is a separate migration and is not part of this change.
- Update launcher label, app header, login/onboarding text, navigation labels, and store-facing display name consistently.
- Keep existing authentication and user data intact.

## Acceptance criteria
- All six agent cards are visible to an authenticated user.
- Each card opens its own agent screen with its own title, purpose, and suggested prompts.
- Empty/loading/error states are handled.
- Protected business data is scoped to the signed-in user or organization.
- External actions (publishing, order changes, payment confirmation) require backend verification and user confirmation.
- Test on Android for navigation, sign-in, network failure, and small-screen layouts.

## Implementation status
This document and the repository README define the requested scope. The Android source files still need to be inspected and updated before these features can be considered implemented or tested.
