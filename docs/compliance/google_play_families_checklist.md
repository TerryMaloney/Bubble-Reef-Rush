# Google Play Families Policy Compliance Checklist — Bubble Reef Rush
**QA-2 Compliance Officer Review**
**Version:** 1.0
**Date:** 2026-06-06
**Policy Reference:** Google Play Families Policy (https://play.google.com/about/families/)
**Program:** Google Play Families (Mixed Audience app targeting ages 6–12)

> **Disclaimer:** This checklist is a best-effort compliance review prepared for internal QA use. It does not constitute legal advice. Policy details are subject to change — verify against current Google Play policy at time of submission. Consult qualified legal counsel before publishing.

---

## Legend

| Status | Meaning |
|--------|---------|
| PASS | Requirement met as designed |
| FAIL | Requirement not met; must fix before submission |
| NEEDS-REVIEW | Cannot confirm from design docs; engineering or legal action required |
| N/A | Not applicable |

---

## Section 1: Age Group Declaration

### 1.1 Target Age Bands

Google Play Families requires developers to declare which age groups the app targets. The available bands are: Ages 5 and under, Ages 6-8, Ages 9-12, and General Audiences (which includes children and adults). Mixed-audience apps can target multiple bands.

| Item | Status | Notes |
|------|--------|-------|
| Primary target: Ages 6-8 and Ages 9-12 | PASS | GDD Section 1 declares target audience as kids ages 6–12. The app spans both Play Families bands. Declare both bands in the Play Console. |
| General Audiences (mixed) flag | NEEDS-REVIEW | If the app is intended for both children and adults (e.g., parents might play too), the "Mixed Audience" designation applies. Mixed-audience apps must comply with the full Families Policy for ALL content and features, not just those sections designated for children. This is the stricter path but is appropriate for this app since all features are child-safe. Recommend: declare Mixed Audience targeting Ages 6-8 and Ages 9-12. |
| Age declaration consistency with content rating | NEEDS-REVIEW | The content rating must be consistent with declared age groups. A PEGI 3 / ESRB Everyone rating is required for Ages 6-8 declaration. Confirm content rating before Play Console submission. |

### 1.2 Mixed Audience Handling

| Item | Status | Notes |
|------|--------|-------|
| All features and content must comply with Families Policy for all users | PASS | GDD Section 8 prohibits ads, loot boxes, chat, FOMO mechanics, and behavioral data collection universally — not just for identified children. The app applies the same safe design to all players. |
| No adult-only sections hidden behind age gate | PASS | There are no age gates within the app separating adult from children's content. All content is appropriate for ages 6+. |

---

## Section 2: Ad Policy

### 2.1 Interest-Based and Behavioral Advertising

Google Play Families Policy prohibits all interest-based advertising in apps targeting children. This includes retargeting, audience targeting, and behavioral profiling.

| Item | Status | Notes |
|------|--------|-------|
| No interest-based advertising | PASS | GDD Section 8.1 item 6: no advertising of any kind. The only revenue sources are two one-time IAPs. |
| No behavioral advertising SDK | PASS | Design prohibits ads. Engineering must confirm no ad SDK is present as a transitive dependency. |
| No AdMob (or if present, configured correctly) | PASS (if absent) | If AdMob is ever added in a future update: it must be configured with `addKeyword("child_directed")` and `RequestConfiguration.Builder().setTagForChildDirectedTreatment(TAG_FOR_CHILD_DIRECTED_TREATMENT_TRUE)`. Do not add without also declaring in the Data Safety section. |

### 2.2 Ad SDKs — Currently None Present

| Item | Status | Notes |
|------|--------|-------|
| No third-party ad network SDK present | PASS | GDD policy prohibits ads. Engineering must confirm at build time. |
| No cross-promotion or house ads for other apps | NEEDS-REVIEW | The game currently has no cross-promotion. If added in the future, any promotion for other apps must: (a) go behind the parental gate if it links outside the app, (b) not use behavioral targeting, (c) be clearly labeled as promotion. |

### 2.3 Future Ad Integration Requirements (If Ads Added)

If ads are ever added to Bubble Reef Rush, ALL of the following must apply before resubmission:

- Use only Families-approved ad networks (Google Play's approved partner list)
- Ads must be non-interest-based, non-retargeted
- No video ads that auto-play
- No full-screen interstitial ads
- No ads featuring real-money gambling content, adult content, or frightening imagery
- Ad placements must not mimic game elements (no fake "play" buttons in ads)
- Parental consent mechanism must be added before ads are shown
- Data Safety section in Play Console must be updated

**Current status: PASS (no ads present). Maintain this status by design.**

---

## Section 3: In-App Purchases

### 3.1 Parental Consent for IAP

Google Play Families Policy requires that all in-app purchases be behind a parental consent mechanism.

| Item | Status | Notes |
|------|--------|-------|
| Parental gate before IAP | PASS | ui_copy.md confirms parental gate: `parental_gate_title = "Quick Check!"`, `parental_gate_prompt = "Ask a grown-up to answer this:"`, `parental_gate_math = "What is {a} + {b}?"`. Gate fires before the purchase flow is initiated. |
| Gate difficulty appropriate to prevent child bypass | NEEDS-REVIEW | See COPPA checklist item 2.2. Math gate operands must be two-digit numbers to prevent the 6-12 age group from easily answering. Engineering must implement and QA must verify the difficulty. |
| Google Play Billing parental controls respected | PASS | GDD Section 8.2 item 1: "Full Reef and Creator Pass IAPs respect device parental control settings. If parental controls require approval for purchases, the game does not attempt to bypass or work around this." |

### 3.2 No Misleading IAP Prompts

Google Play Families Policy prohibits deceptive or manipulative purchase prompts targeting children.

| Item | Status | Notes |
|------|--------|-------|
| IAP prompts only at natural content gates | PASS | GDD Section 7.3 IAP presentation rules: "IAP prompts only appear when player actively reaches the locked content gate (tries to enter Z4 or tries to publish a level)." No prompts in main menu, during levels, or on results screens. |
| No "limited time offer" or urgency language | PASS | GDD Section 8.1 item 2 and item 3 prohibit countdown timers and FOMO mechanics. ui_copy.md contains no urgency language in store strings. |
| No dark patterns (e.g., pre-selected subscriptions, confusing button sizing) | PASS | GDD Section 8.1 item 8: "Purchase screens must clearly state the price, what is included, and that it is a one-time charge. No pre-checked subscription boxes. No confusing button placement ('Not Now' is same size as 'Buy')." |
| No subscriptions | PASS | GDD Section 7.3: no subscriptions. All IAPs are one-time charges. |

### 3.3 Clear Pricing Disclosure

Google Play Families Policy requires that prices be clearly visible before any purchase is initiated.

| Item | Status | Notes |
|------|--------|-------|
| Price visible in IAP button label | PASS | GDD Section 8.2 item 5: "Every button that initiates a purchase shows the price in the button label itself (e.g., 'Unlock Full Reef — $2.99')." ui_copy.md: `product_full_reef_price = "$2.99"`, `product_creator_pass_price = "$1.99"`. |
| One-time charge clearly stated | PASS | GDD Section 8.1 item 8 requires one-time charge disclosure. ui_copy.md `product_full_reef_desc_line1` and `product_creator_pass_desc_line1` describe what is unlocked. Recommend adding explicit "One-time purchase" label to store descriptions if not present. |
| Bundle pricing shown with component prices | NEEDS-REVIEW | The Reef Bundle ($3.99) bundles both IAPs. Play Console requires the bundle price and the individual component prices to be visible so users understand the discount. ui_copy.md does not currently show a `product_reef_bundle_*` entry. Engineering/narrative must add bundle product strings with price and content disclosure. |

### 3.4 No Virtual Currency Schemes Obscuring Real Cost

Google Play Families Policy specifically prohibits virtual currency that obscures the real-money cost of items.

| Item | Status | Notes |
|------|--------|-------|
| No coin bundles sold for real money | PASS | GDD Section 7.3: "No coin bundles." Coins are earned through gameplay only. |
| Coins are not convertible to or from real money | PASS | Coins are in-game only. No real-money value. No exchange mechanism. |
| All IAPs unlock defined content at a fixed price | PASS | GDD Section 7.3: three IAPs at $2.99, $1.99, and $3.99. Each unlocks specifically defined content. No mystery or variable value. |
| No loot boxes or randomized rewards for real money | PASS | GDD Section 8.1 item 7: "All purchasable and earnable items have known, fixed prices and known, fixed unlock conditions. No randomized rewards for real money." |

---

## Section 4: Content Policy

### 4.1 Content Rating

Google Play Families Policy requires apps targeting children under 13 to have a content rating appropriate for children. Apps targeting ages 6-8 must have a PEGI 3 or ESRB Everyone (E) rating.

| Item | Status | Notes |
|------|--------|-------|
| ESRB Everyone (E) content rating target | PASS | GDD Section 8.2 item 2: content must be ESRB E / PEGI 3 throughout. |
| PEGI 3 content rating target | PASS | Same source. |
| No violence | PASS | GDD Section 8.2 item 2: no blood, no death framing. Failure is "bonked," not "died." Obstacle collisions produce cartoon bump animations. |
| No scary content | NEEDS-REVIEW | Zone 5 (Twilight Trench) uses near-total darkness and bioluminescent creatures. Zone 5 unlock requires owning the Full Reef IAP, which requires a parental gate. However, the content rating applies to all content in the app. Art and QA must formally evaluate Zone 5 against PEGI 3 criteria: PEGI 3 allows "very mild non-realistic violence" and prohibits "content that could frighten young children." The dark_void obstacle (which reduces player visibility) must be evaluated — sensory deprivation mechanics may be considered frightening. QA to perform a dedicated content rating pre-assessment of Zone 5 and Zone 6. |
| No gambling or simulated gambling | PASS | GDD Section 8.1 item 7 prohibits loot boxes and randomized rewards. No gambling simulation. |
| No crude humor or language | PASS | ui_copy.md contains only age-appropriate, Grade 3 reading level strings. No crude language. |

### 4.2 User-Generated Content Moderation

Google Play Families Policy requires that apps with UGC have effective moderation systems to prevent harmful content from being displayed to children.

| Item | Status | Notes |
|------|--------|-------|
| UGC (community levels) behind 24-hour moderation queue | PASS | GDD Section 6.5: published levels enter a 24-hour review queue. Levels are not publicly visible until review passes. |
| UGC limited to obstacle placement and level names | PASS | GDD Section 6.1: players can place obstacles and name levels. No free-text chat. No profile photos. No audio recording. |
| Level names and descriptions reviewed before public listing | PASS | GDD Section 8.1 item 10: community level names are pre-moderated. |
| Moderation process documented | NEEDS-REVIEW | GDD states review occurs but does not specify the process. Play Console review may ask about moderation procedures. Operations must document: (a) who reviews content, (b) what criteria are used, (c) what the escalation path is for violations, (d) how creators are notified of rejections. |
| No direct messaging between players | PASS | GDD Section 8.1 item 10: no direct messaging. |
| No comments on community levels | PASS | Same source. |

---

## Section 5: Data Safety Section (Play Console)

The Data Safety form in the Play Console requires developers to declare all data types collected and how they are used. Inaccurate declarations are a policy violation and may result in removal. Complete one entry per data type.

### 5.1 Data Types: What to Declare

| Data Type | Collected? | Shared? | Required? | Security Practice | Notes |
|-----------|-----------|---------|-----------|------------------|-------|
| Name | No | No | No | N/A | No name field in app. |
| Email address | No | No | No | N/A | No email collection. |
| Precise location | No | No | No | N/A | No location permission. |
| Coarse location | No | No | No | N/A | No location permission. |
| Device or other IDs | Yes (GPGS / Game Center player ID) | No (used only for save sync) | Yes (optional, for cloud save) | Data encrypted in transit | Declare: "Device or other IDs" collected, not shared, used for App functionality (cloud save). |
| Purchase history | Yes (platform receipt confirmation) | No | Yes (for IAP verification) | Data encrypted in transit | Declare: "Purchase history" collected by platform SDK, not shared with third parties by the app. |
| App activity — App interactions (level progress, scores, stars, coins) | Yes (local + cloud save) | No | Yes | Data encrypted in transit | Declare: "App interactions" collected for App functionality (save progress). Not shared. |
| App activity — Other user-generated content (level designs) | Yes (if Creator Pass used) | Yes (published to community gallery) | Conditional | Data encrypted in transit | Declare: "Other user-generated content" collected and shared with other users (community gallery). Disclosure: level designs are shared publicly when creator chooses to publish. |
| Crash logs | Yes (if crash SDK present) | Possible (if using third-party crash SDK) | Conditional | Data encrypted in transit | NEEDS-REVIEW: depends on which crash reporting solution is used. If Crashlytics: declare crash logs collected and shared with Firebase (Google). |
| Diagnostics | Possible | Possible | Conditional | N/A | Only if diagnostics SDK is present. Confirm with engineering. |

### 5.2 Data Safety Form: Specific Field Guidance

**Data collected field:**
- Check "Device or other IDs" — used for cloud save via GPGS/Game Center
- Check "Purchase history" — platform processes IAPs
- Check "App interactions" — game progress, scores, and save data
- Check "User-generated content" only if Creator Pass (level sharing) is in scope for this submission

**Data shared field:**
- For all items above except User-generated content: answer "No" — data is not shared with third parties
- For User-generated content (level designs): answer "Yes, shared with other users in the app" (not sold, not used for advertising)

**Security practices:**
- Check "Data is encrypted in transit" — GPGS and Game Center use TLS
- Check "Data can be deleted" — users can delete GPGS/Game Center data via platform account settings
- Do NOT check "Data is collected ephemerally" unless engineering confirms no persistent storage

**Users can request data deletion:**
- GPGS: users can delete game data via Google's account settings (myaccount.google.com)
- Game Center: users can manage via Apple ID account settings
- Declare this on the form

### 5.3 Data Safety Section: Summary Declaration Template

```
App collects the following data types:
1. Device or other IDs: Used for App functionality (cloud save sync). Not shared.
2. Purchase history: Used for App functionality (IAP verification). Not shared.
3. App interactions: Used for App functionality (game progress and score saving). Not shared.
4. User-generated content (level designs): Collected when Creator Pass used.
   Shared publicly within the app only when creator chooses to publish.

All data is encrypted in transit.
Data is not used for advertising or marketing.
Data is not sold.
Users can request deletion via platform account settings.
```

---

## Summary of Required Actions Before Play Console Submission

| # | Action | Owner | Priority |
|---|--------|-------|---------|
| 1 | Confirm no ad SDK present in build | Engineering | Critical |
| 2 | Confirm no behavioral analytics SDK present | Engineering | Critical |
| 3 | Increase parental gate math difficulty to two-digit operands | Engineering | High |
| 4 | Add Reef Bundle product strings to ui_copy.md with price disclosure | Narrative / Engineering | High |
| 5 | Add explicit "One-time purchase" label to store product descriptions | Narrative | Medium |
| 6 | QA content rating pre-assessment of Zone 5 and Zone 6 for PEGI 3 | Art / QA | High |
| 7 | Document community level moderation process (criteria, reviewers, SLA, escalation) | Operations | High |
| 8 | Complete Play Console Data Safety form using Section 5 guidance above | Engineering / Legal | Critical |
| 9 | Legal review of GPGS and Game Center data processing terms | Legal | High |
| 10 | Confirm parental gate fires for zone unlock prompts in addition to Reef Shop | Engineering | High |

---

*End of Google Play Families Policy Compliance Checklist v1.0 — Bubble Reef Rush*
*Prepared by QA-2. Not legal advice. Verify against current Google Play policy at time of submission.*
