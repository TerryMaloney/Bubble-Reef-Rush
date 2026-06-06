# COPPA Compliance Checklist — Bubble Reef Rush
**QA-2 Compliance Officer Review**
**Version:** 1.0
**Date:** 2026-06-06
**Platform Scope:** Android (Google Play Families), iOS (Apple Kids Category)
**Regulatory Scope:** Children's Online Privacy Protection Act (COPPA), 15 U.S.C. § 6501 et seq.; FTC Rule 16 C.F.R. Part 312

> **Disclaimer:** This checklist is a best-effort compliance review prepared for internal QA use. It does not constitute legal advice. Consult qualified legal counsel before submission to any app store or publication to any market.

---

## Legend

| Status | Meaning |
|--------|---------|
| PASS | Requirement is met as designed |
| FAIL | Requirement is not met; action required before shipping |
| NEEDS-REVIEW | Requirement cannot be confirmed from design docs alone; legal/engineering review needed |
| N/A | Requirement does not apply to this product |

---

## Section 1: Data Collection

### 1.1 Personal Information Collected

**Rule cited:** 16 C.F.R. § 312.2 — Definition of "personal information" includes name, email address, telephone number, postal address, persistent identifiers (including device identifiers that can be used to recognize a user over time), geolocation data, photos, videos, and audio.

| Item | Status | Notes |
|------|--------|-------|
| Player name or username collected | PASS | GDD Section 8.1 item 9 prohibits personal data collection beyond platform SDK requirements. No name field exists in the app. |
| Email address collected | PASS | No email sign-up or account creation for the core game. No email field in UI copy review. |
| Phone number collected | PASS | Not collected. No such field exists. |
| Precise geolocation (GPS) | PASS | GDD Section 8.1 item 9 prohibits this. AndroidManifest must not include ACCESS_FINE_LOCATION (see android_manifest_flags.md). |
| Device identifier / Advertising ID (GAID/IDFA) | NEEDS-REVIEW | GDD prohibits behavioral analytics, but engineering must confirm that Google Play Billing SDK and Game Center SDK do not transmit the Advertising ID as a side effect. The game must NOT declare AD_ID permission on Android. Engineering action required: confirm no SDK in the dependency tree reads GAID. |
| Persistent non-advertising device ID (e.g., Android ID for cloud save) | NEEDS-REVIEW | Google Play Games Services uses a persistent player ID for cloud save (GDD Section 5.3). This is a persistent identifier under 16 C.F.R. § 312.2. COPPA permits use of persistent identifiers to support the internal operations of the app without parental consent if the identifier is not used to contact the child, is not disclosed to third parties for non-operational purposes, and does not build a profile. Engineering must confirm GPGS ID is used only for save-data sync and not shared with third parties. Document this in the privacy policy. |

**Action Required (1.1):** Engineering must audit all SDKs for AD_ID access. Document in writing that persistent identifiers from GPGS/Game Center are used solely for cloud save sync (an internal operation). Include in privacy policy.

---

### 1.2 Analytics: Aggregate vs. Individual Tracking

**Rule cited:** 16 C.F.R. § 312.2 — Persistent identifiers used to track children across sites or services are personal information requiring parental consent unless used solely for internal operations. FTC "internal operations" safe harbor requires analytics not be used to build individual profiles or contact children.

| Item | Status | Notes |
|------|--------|-------|
| Aggregate-only analytics (e.g., level clear rates) | PASS | GDD Section 8.1 item 9 explicitly states: "Analytics must be aggregate only (e.g., 'level 3 has a 60% clear rate') — never tied to individual player identity." |
| No individual-level behavioral tracking | PASS | Design policy prohibits individual tracking. |
| No third-party analytics SDK (e.g., Firebase Analytics, Mixpanel, Amplitude) | NEEDS-REVIEW | GDD does not list specific SDK dependencies. Engineering must confirm no analytics SDK is present in the build. If any analytics SDK exists, it must be configured for child-directed treatment (child_directed_treatment=true) and aggregate-only reporting, or removed entirely. |
| Crash reporting SDK (e.g., Crashlytics, Sentry) | NEEDS-REVIEW | Crash data may include device model, OS version, and a session token. This may qualify as a persistent identifier. If a crash SDK is present: (a) confirm it does not collect personal information, (b) confirm it does not use persistent identifiers linked to individuals, (c) disclose in the privacy policy. |

**Action Required (1.2):** Engineering to provide a full list of all SDKs integrated into the build. Legal to evaluate each SDK under the "internal operations" safe harbor. Any analytics SDK must be removed or set to child-directed mode.

---

### 1.3 Cloud Save: Data Stored and Location

**Rule cited:** 16 C.F.R. § 312.8 — Data must be protected with reasonable security measures. Cloud save data involving persistent identifiers requires documentation.

| Item | Status | Notes |
|------|--------|-------|
| Local save data contents | PASS | GDD Section 5.3: best score, star count, play count, first clear date, total coins, characters unlocked. No personally identifiable information. |
| Cloud save via Google Play Games Services (Android) | NEEDS-REVIEW | GPGS assigns a player ID (a pseudonymous persistent identifier tied to the player's Google account). GPGS is a Google service subject to Google's privacy policy. Google restricts GPGS data from being used to build individual profiles of children under 13. Engineering must confirm: (a) only save_data.json contents are synced (scores, stars, coins, unlock flags), (b) no additional personal information is transmitted. |
| Cloud save via Apple Game Center (iOS) | NEEDS-REVIEW | Game Center similarly assigns a player identifier. Apple Kids category guidelines restrict what data Game Center may transmit. Engineering must confirm Game Center use is limited to score and achievement sync, not personal data transmission. |
| Data storage location (server geography) | NEEDS-REVIEW | GPGS and Game Center store data on Google/Apple infrastructure respectively. No first-party servers appear to be used. Confirm this is the case — if a first-party backend exists, COPPA requires reasonable security measures and data retention limits. |

**Action Required (1.3):** Legal to review GPGS and Game Center data processing agreements. Confirm no first-party backend stores child data. Specify cloud save data location in the privacy policy.

---

### 1.4 In-App Purchases: Billing Data Processed

**Rule cited:** 16 C.F.R. § 312.4(d)(2) — Operator must disclose what information is collected from children and how it is used. Billing data processed through platform stores (Google Play, Apple App Store) is handled by the platform, not the app operator, but must be disclosed.

| Item | Status | Notes |
|------|--------|-------|
| Payment processing by platform SDK only | PASS | GDD Section 7.3 lists three one-time IAPs ($2.99, $1.99, $3.99). No direct payment processing by the app — all transactions go through Google Play Billing and Apple StoreKit. The app never receives credit card numbers, billing addresses, or payment tokens. |
| Purchase receipt validation | NEEDS-REVIEW | The app likely receives a purchase receipt token from the platform to verify the purchase. If receipt validation occurs server-side, a first-party server may receive a platform-issued receipt token. This is not personal information about the child, but the privacy policy should disclose that purchase receipts are verified through platform services. If validation is on-device only, disclose this. |
| No subscription billing | PASS | GDD Section 7.3 explicitly states no subscriptions. All IAPs are one-time charges. |
| No coin bundles or virtual currency with obscured real cost | PASS | GDD Section 7.3: no coin bundles. Coins are earned in-game only. No real money maps to virtual currency at any ratio. |

**Action Required (1.4):** Clarify in privacy policy whether purchase receipt validation is on-device or server-side.

---

## Section 2: Parental Consent

### 2.1 Verifiable Parental Consent Mechanism for Under-13

**Rule cited:** 16 C.F.R. § 312.5 — Operators must obtain verifiable parental consent before collecting personal information from children under 13. Exception: operators may collect persistent identifiers used solely for internal operations without consent (16 C.F.R. § 312.5(c)(7)).

| Item | Status | Notes |
|------|--------|-------|
| Verifiable parental consent (VPC) mechanism required for account creation | PASS | No account creation exists for children. No sign-up flow. No email address collected. |
| VPC for personal data collection | PASS | No personal information is collected beyond what may be incidentally processed by GPGS/Game Center for cloud save (covered by platform-level consent mechanisms). |
| Reliance on platform-level parental consent | NEEDS-REVIEW | The app relies on Google Family Link and Apple Screen Time / Family Sharing to manage device-level consent. This is a common and accepted approach but should be documented in the privacy policy. Legal must confirm this reliance is sufficient under the FTC's updated COPPA guidance (2013 amendments). |
| FTC "school operator" safe harbor | N/A | Not applicable — this is a consumer game, not a school-directed service. |

**Action Required (2.1):** Legal to confirm platform-level parental consent reliance is sufficient. Document approach in privacy policy.

---

### 2.2 Parental Gate Before IAP

**Rule cited:** 16 C.F.R. § 312.5(b)(1) — Mechanisms must be reasonably designed to ensure the person providing consent is a parent, not a child. Apple Kids category guidelines require a parental gate before all external links and purchases.

| Item | Status | Notes |
|------|--------|-------|
| Parental gate implemented before IAP trigger | PASS | ui_copy.md documents the gate: `parental_gate_title = "Quick Check!"`, `parental_gate_prompt = "Ask a grown-up to answer this:"`, `parental_gate_math = "What is {a} + {b}?"`. The gate appears before the purchase flow in the Reef Shop. |
| Math question gate design | NEEDS-REVIEW | A simple addition math question (a + b) is the gate mechanism. Apple's App Review guidelines accept this as a parental gate. However, the difficulty of the math question matters — if a and b are both single-digit numbers, a 6-year-old can answer them. Engineering must confirm the values of {a} and {b} are large enough that a child in the 6-12 target age cannot easily compute them (e.g., two-digit addition: 47 + 38). |
| Gate before ALL IAP-adjacent actions | NEEDS-REVIEW | ui_copy.md shows the gate in the store (Reef Shop). Confirm the gate also fires when a player reaches a locked zone (Z4 gate) and is shown the unlock prompt. The gate must precede any action that initiates a purchase dialog, including restore purchases. |
| Gate before external links | NEEDS-REVIEW | Any external links (privacy policy URL, support URL) must be behind the parental gate on iOS (Apple Kids category requirement). Review all links in the app. |

**Action Required (2.2):** Engineering to increase math question difficulty (use two-digit operands). Confirm gate fires for all IAP entry points, zone unlock prompts, and any external links.

---

### 2.3 No Social Features Requiring Account Creation for Children

**Rule cited:** 16 C.F.R. § 312.2 — Account creation for children under 13 constitutes collection of personal information and requires VPC. 16 C.F.R. § 312.5(c)(7) — no VPC needed for persistent identifiers used solely for internal operations.

| Item | Status | Notes |
|------|--------|-------|
| No account creation (username/password) required for core gameplay | PASS | GDD Section 8.1 item 10: no account creation for children. All gameplay is available without registration. |
| Community features (level sharing) require Creator Pass IAP only | PASS | Community gallery access requires the $1.99 Creator Pass. No personal account is created — the system uses the platform's game services player ID pseudonymously. |
| No free-text public chat | PASS | GDD Section 8.1 item 10 explicitly prohibits chat, comments, and direct messaging. |
| Community level names are pre-moderated | PASS | GDD Section 6.5: levels enter a 24-hour review queue before going public. Level names and descriptions are reviewed before publication. |
| No social comparison notifications | PASS | GDD Section 8.1 item 5 prohibits "your friend beat your score" notifications. Leaderboards (if added) are friends-only and opt-in. |

---

## Section 3: Third-Party SDKs

### 3.1 SDK Inventory

**Rule cited:** 16 C.F.R. § 312.2 — An operator is responsible for the data practices of third-party services it uses. FTC guidance (2013): operators must obtain parental consent for third-party data collection unless the third party acts as a service provider processing data solely on the operator's behalf.

| SDK / Service | Purpose | Data Collected | Status | Notes |
|--------------|---------|----------------|--------|-------|
| Google Play Billing | IAP processing (Android) | Purchase tokens, transaction IDs (platform-side) | PASS | App never receives payment data directly. Google processes billing under its own COPPA-compliant terms. No behavioral advertising data. |
| Apple StoreKit | IAP processing (iOS) | Purchase receipts (platform-side) | PASS | Same as above. Apple processes billing under its own COPPA-compliant terms. |
| Google Play Games Services (GPGS) | Cloud save, achievements (Android) | Pseudonymous player ID, save data | NEEDS-REVIEW | GPGS is Google's service for game data. It uses a persistent player ID tied to the Google account. If the Google account belongs to a child in a Google Family Link setup, Google applies child-appropriate protections. Engineering must confirm GPGS is not collecting beyond save data. |
| Apple Game Center | Cloud save, achievements (iOS) | Pseudonymous player ID, save data | NEEDS-REVIEW | Same analysis as GPGS. Confirm Game Center usage is limited to the save and achievement sync described in GDD Section 5.3. |
| Godot Engine runtime | Game engine | No data collection by engine itself | PASS | Godot 4.x is an open-source engine that does not include built-in telemetry or data collection. However, any Godot plugin (e.g., GDNative module) added to the build must be audited separately. |
| Crash reporting SDK (unspecified) | Crash/error reporting | Device info, stack traces, possible session IDs | NEEDS-REVIEW | GDD does not specify a crash SDK. If one is included (e.g., Firebase Crashlytics), it must be configured with child-directed treatment or scoped to aggregate-only data. |

**Action Required (3.1):** Engineering to produce a complete SDK dependency manifest. Legal to review each SDK's data processing terms for COPPA compliance. Document all SDKs in the privacy policy.

---

### 3.2 Behavioral Advertising SDKs

**Rule cited:** 16 C.F.R. § 312.2 — Interest-based advertising directed at children under 13 constitutes collection of personal information requiring VPC. FTC and state AGs have enforced this aggressively.

| Item | Status | Notes |
|------|--------|-------|
| No behavioral advertising SDKs present | PASS | GDD Section 8.1 item 6 prohibits all advertising: "No third-party ads of any kind — not banner, not interstitial, not rewarded video ads." No ad SDK is present by design. |
| No AdMob, MoPub, Unity Ads, AppLovin, ironSource, or similar | PASS | Design policy prohibits ads. Engineering must confirm none are present in the build (including as transitive dependencies). |
| No contextual advertising SDKs | PASS | No advertising of any kind is present. |

---

### 3.3 Analytics SDKs: Safety Assessment

**Rule cited:** 16 C.F.R. § 312.5(c)(7) — Persistent identifiers may be used without VPC for internal operations, including analytics that do not build individual profiles.

| Scenario | Status | Notes |
|----------|--------|-------|
| No analytics SDK present (preferred) | PASS (if confirmed) | The safest configuration for a kids app is no third-party analytics SDK. Aggregate play data can be derived from cloud save (e.g., level completion rates via GPGS leaderboard data). |
| First-party aggregate analytics (on-device, no PII) | PASS | Acceptable if: no persistent identifier linked to individual, data aggregated before any transmission, no individual-level data leaving device. |
| Firebase Analytics with child_directed_treatment=true | NEEDS-REVIEW | If Firebase is used: must set `FirebaseAnalytics.setUserProperty("child_directed_treatment", "true")`. This disables advertising IDs and limits data collection. Still requires privacy policy disclosure and may not satisfy Apple Kids requirements. |
| Any SDK that builds individual behavioral profiles | FAIL | This would require VPC and is contrary to GDD design policy. Must not be included. |

---

## Section 4: Content

### 4.1 Age-Appropriate Content

**Rule cited:** COPPA does not directly regulate content ratings, but operating under ESRB E / PEGI 3 supports the claim that the app is directed at children under 13 (16 C.F.R. § 312.2(b)(1)(ii)).

| Item | Status | Notes |
|------|--------|-------|
| ESRB E / PEGI 3 content target | PASS | GDD Section 8.2 item 2: content must be ESRB E / PEGI 3 throughout. No blood, no death framing, failure is "bonked" not "died." |
| Failure language is non-frightening | PASS | ui_copy.md: fail messages are "So close! Give it one more try!" and "Almost there! You can do it!" No "Game Over," no "You failed." |
| No violence | PASS | Obstacle collisions produce cartoon bump animations (flash red/white, squish). No blood, no death. |
| No chat or user-generated text in public spaces | PASS | GDD Section 8.1 item 10 prohibits all public text chat and comments. Level names are pre-moderated before publication. |
| Frightening imagery | PASS | Zone 5 (Twilight Trench) uses darkness and bioluminescent creatures. GDD Section 8.2 item 2 requires no frightening imagery. The dark_void obstacle reduces visibility but does not present scary characters. Engineering and art must confirm Zone 5 imagery passes PEGI 3 review. |

### 4.2 Community Level Names: Pre-Moderation

**Rule cited:** 16 C.F.R. § 312.2 — User-generated content visible to children constitutes a public disclosure risk. COPPA does not specifically regulate UGC names, but FTC guidance recommends moderation.

| Item | Status | Notes |
|------|--------|-------|
| 24-hour review queue before public listing | PASS | GDD Section 6.5: published levels enter a 24-hour community review queue. During review, level is visible only to creator. |
| Moderation process defined | NEEDS-REVIEW | GDD states levels must pass a review but does not describe the moderation method (automated, human, or hybrid). Legal and operations must define the moderation SLA and process. This is especially important as the app targets children under 13. |
| No free-text comments on community levels | PASS | GDD Section 8.1 item 10: no comments on levels. |

**Action Required (4.2):** Define and document the community level moderation process. Consider automated profanity filtering as the first pass, with human review for flagged content.

---

## Summary of Required Actions Before Ship

| # | Action | Owner | Priority |
|---|--------|-------|---------|
| 1 | Engineering SDK audit: confirm no AD_ID permission, no behavioral analytics SDK | Engineering | Critical |
| 2 | Confirm GPGS and Game Center data limited to save sync; no PII transmitted | Engineering | Critical |
| 3 | Increase parental gate math difficulty to two-digit operands | Engineering | High |
| 4 | Confirm parental gate fires for ALL IAP entry points including zone unlock prompts and external links | Engineering | High |
| 5 | Legal review of GPGS and Game Center DPAs for COPPA compliance | Legal | High |
| 6 | Privacy policy drafted, reviewed by attorney, published at a reachable URL | Legal | Critical |
| 7 | Define community level moderation process (automated + human review SLA) | Operations | High |
| 8 | Confirm crash reporting SDK (if present) is configured for child-directed treatment | Engineering | High |
| 9 | Confirm no first-party backend stores child data; if one exists, implement security and retention limits | Engineering/Legal | Critical |
| 10 | Art/QA: confirm Zone 5 imagery passes PEGI 3 evaluation | Art / QA | Medium |

---

*End of COPPA Compliance Checklist v1.0 — Bubble Reef Rush*
*Prepared by QA-2. Not legal advice. Reviewed by legal counsel required before publishing.*
