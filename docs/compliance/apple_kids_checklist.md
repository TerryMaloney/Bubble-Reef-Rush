# Apple App Store Kids Category Compliance Checklist — Bubble Reef Rush
**QA-2 Compliance Officer Review**
**Version:** 1.0
**Date:** 2026-06-06
**Policy Reference:** Apple App Review Guidelines § 1.3 (Kids Category), § 5.1.4 (Kids Apps)
**Target Category:** Kids (Ages 6-8 and Ages 9-11)

> **Disclaimer:** This checklist is a best-effort compliance review prepared for internal QA use. It does not constitute legal advice. Apple's guidelines are subject to change and are interpreted by reviewers who apply judgment. Verify against current guidelines at https://developer.apple.com/app-store/review/guidelines/ at time of submission.

---

## Legend

| Status | Meaning |
|--------|---------|
| PASS | Requirement met as designed |
| FAIL | Requirement not met; must fix before submission |
| NEEDS-REVIEW | Cannot confirm from design docs; action required |
| N/A | Not applicable |

---

## Section 1: Age Rating Selection

### 1.1 Kids Category Sub-Band

Apple's Kids category has three sub-bands: Ages 5 and Under, Ages 6-8, and Ages 9-11. Apps may be listed in one sub-band only.

| Item | Status | Notes |
|------|--------|-------|
| Target sub-band: Ages 6-8 or Ages 9-11 | NEEDS-REVIEW | The GDD targets ages 6–12. This spans two Apple sub-bands. Apple does not allow a single app to be listed in multiple Kids sub-bands. The developer must choose one. Recommendation: list in Ages 9-11, because the game has meaningful rhythm complexity (timing windows, BPM changes, combo mechanics) that is better suited to the upper range of the audience. However, Zone 1 is intentionally gentle enough for 6-year-olds. The alternative is to target Ages 6-8 and ensure the game's hardest content (Zones 4-6) can only be reached after significant play, giving younger children a gradual difficulty ramp. Legal and product must decide before App Store Connect submission. |
| Content rating: 4+ | PASS | Apple's Age Rating for a Kids sub-band app should be 4+. The GDD targets ESRB E / PEGI 3, which maps to 4+. This means: no objectionable content, no mature themes, no frequent mild cartoon violence. The game as designed meets this threshold. |
| Content rating: 9+ (avoid) | N/A | A 9+ rating would be assigned if the content includes infrequent mild cartoon violence, mild suggestive themes, or simulated gambling. The game has no gambling, no suggestive themes, and only cartoon bump impacts. Do not select 9+ unless App Review applies it during review. |

---

## Section 2: Parental Gate Requirements

Apple guideline § 5.1.4(i) states: "Kids Apps may not include links that take customers outside the app or social networking references without first going through a parental gate." § 1.3(ii) requires parental gates before all external links, social networks, purchases, and other content not appropriate for the primary child audience.

### 2.1 Parental Gate — Scope

| Item | Status | Notes |
|------|--------|-------|
| Parental gate before all in-app purchases | PASS | ui_copy.md: parental gate is implemented with a math question (`parental_gate_math = "What is {a} + {b}?"`). Gate fires before the IAP purchase flow. |
| Parental gate before all external links | NEEDS-REVIEW | Any link to a website (privacy policy URL, support URL, App Store page for another app) must be behind the parental gate. Engineering must audit all URLs in the build and confirm every external link passes through the gate. Common failure points: (a) Settings screen "Privacy Policy" link, (b) "Rate Us" or "More Apps" links, (c) support email/URL in error screens. None of these are visible in ui_copy.md but they are likely present. |
| Parental gate before social network links | PASS | No social network links are designed into the app. If added in the future, they must go behind the gate. |
| Parental gate before linking to other apps | NEEDS-REVIEW | If there is any "also made by us" promo or App Store link to another app, it must be behind the gate. GDD does not describe cross-promotion; confirm none is present. |
| Parental gate implementation: math question | PASS | Apple accepts math questions as a valid parental gate mechanism. The current design (`parental_gate_prompt = "Ask a grown-up to answer this:"`) correctly directs the question to a parent. |
| Math question difficulty | NEEDS-REVIEW | See COPPA checklist item 2.2. Single-digit addition is within the range of the 6-12 age group. Apple reviewers may test the gate themselves. Two-digit addition operands are recommended. Engineering must confirm operand values before submission. |

### 2.2 What Does NOT Need a Parental Gate

For clarity — Apple's parental gate requirement is specifically for content leaving the app or social features. The following do NOT require a gate:
- Navigating between screens within the app
- Playing levels and using all core gameplay features
- Spending in-game coins on cosmetics
- Accessing community levels (viewing and playing)
- Settings and accessibility controls
- Viewing the character roster

---

## Section 3: No Behavioral Advertising

Apple guideline § 1.3(iii) and § 5.1.4(i): Kids Apps may not include behavioral advertising or share data with third parties for advertising purposes.

| Item | Status | Notes |
|------|--------|-------|
| No behavioral advertising | PASS | GDD Section 8.1 item 6: no advertising of any kind. |
| No ad SDK present | PASS | Design policy prohibits ads. Confirm at build time. |
| No use of IDFA (Identifier for Advertisers) | PASS | The game must not request ATT (App Tracking Transparency) permission. Kids apps should not request ATT. If any SDK in the build triggers an ATT prompt, that SDK must be removed or reconfigured. Engineering must confirm no ATT prompt is triggered. |
| Apple SKAdNetwork (contextual ads) | N/A | Not applicable — no ads present. |

---

## Section 4: Data Collection Restrictions

Apple guideline § 5.1.4(ii): Apps in the Kids category may not transmit data about a minor to third parties. Apple privacy guidelines require a privacy nutrition label that accurately reflects all data collected.

### 4.1 Data Collection Limits

| Item | Status | Notes |
|------|--------|-------|
| No personal data collection from children | PASS | GDD Section 8.1 item 9 prohibits personal data collection beyond platform SDK requirements. No name, email, or location collected. |
| No data sharing with third parties for non-operational purposes | PASS | GDD design prohibits sharing data. GPGS/Game Center are platform services operating under their own Apple/Google policies. |
| StoreKit purchase processing — Apple only handles billing | PASS | The app uses Apple StoreKit for IAP. Apple processes billing. The app receives only a purchase receipt confirmation, not payment details. |
| Game Center data transmission | NEEDS-REVIEW | Game Center transmits a pseudonymous player ID and game data (scores, achievements). Apple applies child-specific protections when the Game Center account belongs to a child (via Family Sharing). Engineering must confirm Game Center use is limited to save data and achievement sync as described in GDD Section 5.3. |
| No microphone, camera, or photo library access | PASS | GDD and ui_copy.md describe no such features. Confirm no such permissions are requested in the app. |

### 4.2 No Third-Party Analytics Without Parental Consent

Apple guideline § 5.1.4(ii): Third-party analytics SDKs in Kids category apps must not collect or transmit personally identifiable information.

| Item | Status | Notes |
|------|--------|-------|
| No third-party analytics SDK | PASS (if confirmed) | GDD design policy is no individual-level analytics. If no analytics SDK is present, this passes. |
| If analytics SDK is present: must be approved by Apple | NEEDS-REVIEW | Apple requires that any third-party analytics in a Kids app be reviewed and approved. Apple maintains a list of accepted SDKs for the Kids category. Any analytics SDK that transmits data off-device must be on Apple's approved list or must be removed. Engineering must confirm SDK list. |
| Crash reporting SDK | NEEDS-REVIEW | Crash SDKs (e.g., Firebase Crashlytics) may be considered analytics by Apple reviewers. If present, confirm it does not transmit device-identifiable information. Aggregate crash data (OS version, device model, stack trace without user ID) is generally acceptable; crash data linked to a player identity is not. |

---

## Section 5: Age Rating — 4+ vs 9+

### 5.1 Apple Age Rating Questionnaire Analysis

Apple's Age Rating questionnaire asks about specific content categories. Based on GDD content:

| Content Category | Present? | Rating Impact |
|-----------------|---------|--------------|
| Cartoon or fantasy violence | Minimal (cartoon bump/squish on obstacle hit) | 4+ (cartoon impacts are allowable at 4+) |
| Realistic violence | No | No impact |
| Animated blood | No | No impact |
| Prolonged graphic or sadistic realistic violence | No | No impact |
| Sexual content or nudity | No | No impact |
| Suggestive or mature themes | No | No impact |
| Simulated gambling | No | No impact |
| Horror/fear themes | Possible (Zone 5 darkness) | Assess (see below) |
| Profanity or crude humor | No | No impact |
| Mature/suggestive themes | No | No impact |
| Alcohol, tobacco, drugs | No | No impact |

**Recommended rating: 4+**

Zone 5's dark_void mechanic and near-total darkness setting should be assessed against Apple's 4+ threshold. The dark_void reduces screen visibility and plays "heartbeat-style bass pulse" audio (GDD Section 2.10). This is atmospheric and not inherently frightening in the same way as horror imagery. However, QA should test Zone 5 with reviewers in the 6-8 age range to confirm it does not feel scary. If Apple Review assigns 9+ due to Zone 5 content, the team should accept it — 9+ is still within the Kids category Ages 9-11 sub-band.

---

## Section 6: Required Privacy Policy URL

Apple guideline § 5.1.1 and App Store Connect requirement: All apps in the Kids category must provide a privacy policy URL. The privacy policy must be publicly accessible (not behind a login), written in plain language, and accurately describe data practices.

| Item | Status | Notes |
|------|--------|-------|
| Privacy policy URL provided in App Store Connect | NEEDS-REVIEW | A privacy policy URL must be entered in App Store Connect before the app can be submitted. The privacy_policy_draft.md in this compliance package provides a draft. Legal must review and finalize, then host at a public URL (e.g., https://[yourdomain].com/privacy). |
| Privacy policy accessible within the app | NEEDS-REVIEW | Apple strongly recommends (and Kids category guidelines effectively require) that the privacy policy be accessible within the app itself — not only via App Store Connect. Engineering should add a "Privacy Policy" link in the Settings screen. This link must go behind the parental gate (it links externally). |
| Privacy policy written in plain language | PASS | The privacy_policy_draft.md in this package is written in plain English, readable in approximately 2 minutes. |
| Privacy policy covers Kids category requirements | NEEDS-REVIEW | Legal must confirm the privacy policy explicitly addresses: (a) no behavioral advertising, (b) what data GPGS/Game Center collect, (c) how parents can request data deletion, (d) COPPA statement. The draft privacy policy in this package includes these sections. |

---

## Section 7: Kids Category: What Is Restricted vs. Allowed

### 7.1 Restricted (Must NOT Be Present)

| Restriction | Status | Source |
|-------------|--------|--------|
| Behavioral advertising | PASS — not present | App Review § 1.3(iii) |
| Third-party analytics that collect PII | PASS — not present by design | App Review § 5.1.4(ii) |
| External links not behind parental gate | NEEDS-REVIEW | App Review § 1.3(ii) |
| Social network integration without parental gate | PASS — no social network integration | App Review § 1.3(ii) |
| In-app purchases without parental gate | PASS — gate implemented | App Review § 1.3(ii) |
| Requesting notification permissions (push) | PASS — GDD Section 8.1 item 4 prohibits push notifications | App Review § 5.1.4 |
| IDFA / ATT tracking prompt | PASS — no ads, should not be present | App Tracking Transparency framework |
| Microphone / camera access | PASS — not used | App Review § 5.1.4 |
| Account creation without parental consent | PASS — no account creation | App Review § 5.1.4, COPPA |
| Content rated above the declared sub-band | NEEDS-REVIEW | App Review § 4.1, Age Rating questionnaire |
| Real-money loot boxes or randomized IAP rewards | PASS — not present | App Review § 3.1.1, GDD Section 8.1 item 7 |

### 7.2 Allowed (Permitted in Kids Category)

| Feature | Allowed? | Notes |
|---------|---------|-------|
| One-time in-app purchases | Yes | With parental gate. GDD has three one-time IAPs. |
| Offline gameplay | Yes | GDD Section 8.2 item 4 ensures all unlocked content works offline. |
| Cloud save via Game Center | Yes | Game Center is Apple's own platform service, permitted. |
| Achievements via Game Center | Yes | Same as above. |
| Local leaderboards / personal best scores | Yes | No sharing required. |
| User-generated content (level creation) | Yes | With moderation (24-hour review queue). |
| Community content (playing other players' levels) | Yes | With moderation gate. |
| Cosmetic items purchasable with in-game coins | Yes | Coins are earned through gameplay, not purchased. |
| In-game sounds and music | Yes | No issues. |
| Vibration haptics | Yes | Standard gameplay haptics are allowed. |

---

## Summary of Required Actions Before App Store Connect Submission

| # | Action | Owner | Priority |
|---|--------|-------|---------|
| 1 | Product decision: declare Ages 6-8 or Ages 9-11 sub-band | Product / Legal | Critical |
| 2 | Audit all external links in build; confirm all are behind parental gate | Engineering | Critical |
| 3 | Increase parental gate math difficulty (two-digit operands) | Engineering | High |
| 4 | Confirm no ATT prompt is triggered (no IDFA access) | Engineering | Critical |
| 5 | Confirm no third-party analytics SDK transmits PII | Engineering | Critical |
| 6 | QA Zone 5 content for 4+ age rating appropriateness | Art / QA | High |
| 7 | Host privacy policy at public URL; enter in App Store Connect | Legal / Engineering | Critical |
| 8 | Add Privacy Policy link inside app Settings screen (behind parental gate) | Engineering | High |
| 9 | Confirm Game Center use limited to save and achievement sync | Engineering | High |
| 10 | Complete App Store Connect Privacy Nutrition Label (mirrors Play Data Safety) | Engineering / Legal | Critical |

---

*End of Apple App Store Kids Category Compliance Checklist v1.0 — Bubble Reef Rush*
*Prepared by QA-2. Not legal advice. Verify against current Apple guidelines at time of submission.*
