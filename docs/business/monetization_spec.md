# Bubble Reef Rush — Monetization Specification
**Version:** 1.0  
**Author:** Monetization Designer B-2  
**Status:** Binding design document — all IAP flows and pricing must implement this exactly  
**Audience:** Engineering, product, legal, platform submission teams

---

## 1. Revenue Model Summary

### 1.1 Model: Free to Play + Two One-Time Non-Consumable IAPs

Bubble Reef Rush is free to download and free to play meaningfully. There are exactly three purchasable products:

| Product | Price | Type |
|---|---|---|
| Unlock Full Reef | $2.99 | One-time non-consumable |
| Creator Pass | $1.99 | One-time non-consumable |
| Reef Bundle (both above) | $3.99 | One-time non-consumable (bundle) |

**No subscriptions.** No consumable currency packs. No loot boxes. No randomized rewards. No advertising of any kind. No energy systems. No lives. These are not omissions — they are deliberate design choices documented and enforced as safety policy (see Section 7 and GDD Section 8).

### 1.2 Why This Model

**Trust is the product.** Parents are the actual purchase decision-maker for this age group (6–12). A parent who trusts the monetization model will allow their child to play more, recommend the app to other parents, and leave positive store reviews. The entire revenue model is designed to be explainable in one sentence to a skeptical parent: "It's free. There's one upgrade to unlock more levels ($2.99) and one for the level editor ($1.99). That's it, forever."

**COPPA and platform compliance by construction.** By having only non-consumable IAPs, there is no coin-purchasing pathway, which eliminates the most common COPPA risk vector (children spending money repeatedly through ambiguous store flows). Each purchase is a one-time, clearly labeled, parent-approved transaction.

**Simplicity reduces abandonment.** Complex monetization (battle passes, rotating shops, limited offers) requires cognitive overhead that alienates parents and confuses young players. One price, one decision, permanent ownership. A parent who buys once never needs to revisit the store.

**Long-term reputation.** A single negative App Store review citing manipulative monetization causes more damage to a kids' app than the revenue from that mechanic ever produces. The model is designed so that the most hostile review a parent could write about the monetization is: "You have to pay $2.99 for the extra levels." That is a fair trade, not a complaint.

---

## 2. What Is Free vs Paid

### 2.1 Free Content (No Purchase Required, Ever)

**Zones and Levels:**
- Zone 1 — Sunlit Shallows: All 8 levels (Z1-L1 through Z1-L8) — fully free
- Zone 2 — Kelp Forest Canyon: All 8 levels (Z2-L1 through Z2-L8) — fully free
- Zone 3 — Shipwreck Alley: All 8 levels (Z3-L1 through Z3-L8) — fully free
- Zone 6 — Crystal Caves: All 8 levels (Z6-L1 through Z6-L8) — earned free by achieving 3 stars on all 40 levels in Zones 1–5; never purchasable

**Total free levels: 24 story levels + 8 secret/earned levels = 32 levels accessible without payment**

**Characters:**
All 8 characters are earnable through gameplay — none are purchasable with real money except Finn, who is included with Full Reef as a bonus (not sold separately). Free-to-earn characters:
- Pebble (Pufferfish) — default, always unlocked
- Zap (Electric Ray) — complete Zone 2
- Mochi (Moon Jellyfish) — earn 50 total stars
- Crusher (Hermit Crab) — earn 3 stars on any 4 Zone 3 levels
- Pip (Sea Turtle) — earn 3 stars on all Zone 1 levels
- Lumina (Anglerfish) — complete Zone 5 (requires Full Reef, but the character earn itself is free)
- Grumble (Giant Isopod) — earn 3 stars on Zone 6-L8 (the hardest earn in the game)

**Build Mode:**
- Level editor with full beat-grid placement
- All obstacle types from personally unlocked zones
- Speed zone editor
- Zone/background selection from unlocked zones
- Music selection from unlocked zone tracks
- Level name and description text
- 5 saved levels (local storage)
- Local level sharing via direct share code (recipient requires Creator Pass to download)

**Economy:**
- Coin earning from all gameplay actions (see Section 5)
- All coin-purchased cosmetics (trail colors, outfits, UI themes, background palettes, beat ring variants) — earnable without spending real money

### 2.2 Unlock Full Reef ($2.99 — One-Time)

**Unlocks immediately upon purchase:**
- Zone 4 — Volcanic Vent Fields: 8 levels (Z4-L1 through Z4-L8)
- Zone 5 — Twilight Trench: 8 levels (Z5-L1 through Z5-L8)
- Finn (Great White Shark) character — immediately playable, no additional earn condition
- Access path to Zone 6 unlock condition (since Zone 6 requires 3 stars on all Z1–Z5 levels, owning Full Reef is a prerequisite for the secret zone — this is stated clearly in the IAP prompt)
- All future zone DLC if additional zones are added post-launch (this commitment must be honored — see Section 6.3)

**Does NOT unlock:**
- Creator Pass features (publishing, gallery, extra editor obstacles)
- Any coin cosmetics — those remain earn-only

**Total additional content: 16 levels + 1 character**

### 2.3 Creator Pass ($1.99 — One-Time)

**Unlocks immediately upon purchase:**
- Public gallery publishing (levels go through 24-hour moderation queue then appear publicly)
- Community gallery browsing (download and play other players' published levels)
- Unlimited saved levels (removes the 5-level local cap)
- Full obstacle catalog in the level editor, including obstacles from zones the player has not yet personally unlocked in story mode
- Eighth-beat and sixteenth-beat grid subdivisions in the editor (these are also unlocked by reaching Zone 3 and Zone 5 respectively through gameplay — Creator Pass provides them immediately)

**Does NOT unlock:**
- Story zones or levels
- Finn character
- Any coin cosmetics

### 2.4 Reef Bundle ($3.99 — One-Time)

Both Unlock Full Reef and Creator Pass at a combined $1.00 discount vs. buying separately ($4.98 total → $3.99 bundle).

The bundle is a single purchasable product. Upon purchase, both product entitlements are granted simultaneously. Platform receipt validation must check for either the bundle product ID or the individual product IDs when determining unlock status — owning any combination of individual products plus bundle must not result in double-charging. Standard non-consumable restore logic applies.

**Savings framing:** The bundle saves $0.99. This is a genuine, calculable discount. The store screen may say "Save $1!" (rounding up is acceptable as $0.99 rounds to $1). Do not say "Save 20%" — percentage framing is harder for young readers and their parents to quickly verify.

---

## 3. IAP Presentation Rules

These rules are binding. Implementation that deviates requires explicit sign-off from the product lead and a documented rationale. The goal is that a parent who sees an IAP prompt feels informed and respected, not pressured.

### 3.1 When IAP Prompts Appear

**Full Reef prompt triggers:**
- Player taps to enter Zone 4 (Volcanic Vent Fields) without owning Full Reef
- Player taps to enter Zone 5 (Twilight Trench) without owning Full Reef
- Player taps the "Unlock Zone" button on the Zone Select screen for Zone 4 or Zone 5

**Creator Pass prompt triggers:**
- Player taps "Share with Friends!" (publish button) in Build Mode without owning Creator Pass
- Player taps a gallery level from the community section without owning Creator Pass
- Player attempts to save a 6th local level without owning Creator Pass

**Never prompt in:**
- Main menu (even as a banner or featured item)
- During active gameplay (levels)
- On the Results screen (win or fail)
- In the Settings screen
- As a push notification (push notifications are prohibited entirely — GDD 8.1 Rule 4)
- As a pop-up on first launch or during onboarding
- At any timed interval ("you've been playing 30 minutes, want to upgrade?")

### 3.2 What the IAP Prompt Must Contain

Every IAP prompt must display all of the following. No element may be omitted.

**Required elements:**
1. **Product name** — exact name matching App Store / Google Play listing (e.g., "Unlock Full Reef")
2. **Exact price** — the localized price from the platform's billing API, displayed prominently, in the button itself (e.g., "Get It — $2.99"). Never display a hardcoded price string — always pull from the platform SKU to ensure regional accuracy.
3. **What is unlocked** — a short, specific, non-vague description of exactly what the player gets. Examples:
   - Full Reef: "Play Zones 4 and 5 — 16 more levels plus Finn the shark!"
   - Creator Pass: "Publish your levels for everyone to play, unlimited saves, and all obstacles!"
   - Bundle: "Everything in Full Reef and Creator Pass — both at once!"
4. **One purchase button** — labeled with product name + price (from platform API)
5. **One dismiss button** — labeled with a neutral phrase such as "No thanks" or "Maybe later"
6. **Parental gate** — must be passed before the payment sheet appears (see Section 3.3)

**Prohibited elements in IAP prompt:**
- Countdown timers or urgency language ("Only today!", "Limited offer!")
- Star ratings or review counts
- Comparison language ("Everyone else bought this!")
- Vague unlock descriptions ("Unlock premium content", "Get the full experience")
- Guilt-trip dismiss text ("No thanks, I don't want more levels" — this is a dark pattern)
- Pre-selected options
- More than one buy action (no upsell to bundle inside individual product prompt — the bundle should be an alternative choice, not an upsell)

### 3.3 Parental Gate

Before the platform payment sheet appears, the player must pass a math question parental gate. This gate must be presented every time, with no option to remember or bypass it on subsequent purchases.

**Gate implementation:**

The gate uses UI copy key `parental_gate_math` from `ui_copy.md`:
```
parental_gate_title: "Quick Check!"
parental_gate_prompt: "Ask a grown-up to answer this:"
parental_gate_math: "What is {a} + {b}?"
parental_gate_wrong: "Hmm, not quite! Try again."
parental_gate_success: "Got it! Here you go."
```

**Math question generation rules:**
- `{a}` and `{b}` are integers, each between 11 and 49 (inclusive)
- Sum must be between 30 and 80 (prevents trivially easy questions like 1+1 and prevents two-column carries that frustrate non-math-confident adults)
- Numbers are randomized on each gate presentation — do not use a fixed question
- The gate accepts a numeric text input and checks the exact integer sum
- Maximum 3 attempts, then the gate resets with new numbers (no lockout — just new numbers)
- The gate's purpose is to require a parent's involvement, not to prevent purchase. It must not be so hard that it blocks legitimate parents.

**Gate placement in flow:**
```
Player hits locked content gate
  → IAP prompt screen shown (product info, price, buttons)
  → Player taps purchase button
  → Parental gate overlay appears
  → Player enters correct answer
  → Platform payment sheet launches (App Store / Google Play native)
  → On payment success → entitlement granted
  → On payment cancel / failure → return to IAP prompt, show error message from ui_copy.md key error_purchase_failed_body
```

### 3.4 "No Thanks" / Dismiss Behavior

- The dismiss button must be **visually identical in size** to the purchase button. Same font size, same button height, same horizontal weight. Color differentiation is acceptable (e.g., purchase button uses accent color, dismiss is outlined), but the dismiss button must not appear smaller, grayed-out to illegibility, or harder to tap.
- Tapping dismiss closes the IAP prompt and returns the player to where they were.
- After a dismiss, the game must **not re-prompt for the same trigger for 48 hours**. This is tracked locally by storing a timestamp per product ID. The 48-hour window resets if the player manually navigates to the Reef Shop screen (they have shown opt-in intent).
- The game must **never prompt twice in a single session** for the same product, regardless of the 48-hour timer.
- There is no "remind me later" option, no "I'll think about it" flow, and no follow-up notification. Dismiss means dismiss.

---

## 4. Cosmetic Item Pricing (Future — Post-Launch)

This section governs the pricing structure for optional cosmetic IAPs if they are added after launch. No cosmetic IAPs exist at launch. Any cosmetic IAP addition requires a new version submission and must comply with all rules in this section.

### 4.1 Price Tiers

| Item Type | Price Range | Examples |
|---|---|---|
| Individual character color/pattern variant | $0.99 | Rainbow Puff (Pebble), Midnight Zap (Zap) |
| Character accessory | $0.99–$1.49 | Hat, held item, trail effect variant |
| UI theme (full menu reskin) | $1.99 | Seasonal theme (only if permanent — no expiry) |
| Cosmetic bundle (3–5 items) | $1.99–$4.99 | "Ocean Festival Pack" (3 skins) |

**Floor rule: No cosmetic item or bundle priced below $0.99.** Sub-dollar pricing devalues the items and signals "cheap" to parents in a way that paradoxically erodes trust.

**Ceiling rule: No cosmetic bundle priced above $4.99.** This is the maximum ask for cosmetics in a kids' game. A parent who sees $7.99 for a cosmetic pack will leave a negative review, even if they would pay $4.99 without complaint.

### 4.2 Absolute Rules for Cosmetic IAPs

- **Characters are never sold as cosmetics.** All 8 base characters remain earn-only. If new characters are added post-launch, they must also be earnable through gameplay — they may optionally be purchasable as an alternative path, but an earn path must exist.
- **No character POWER is ever sold.** All characters always have identical physics, collision boxes, timing windows, and combo behavior, regardless of what the player has purchased. This is a non-negotiable design rule per GDD Section 4.1.
- **No power-up cosmetics.** A cosmetic item may not provide any gameplay advantage — no coin-earn bonuses, no wider timing windows, no hit invincibility, no score multipliers.
- **All cosmetics are permanent.** Once purchased, a cosmetic is owned forever. No expiry. No "season passes" that render past purchases obsolete.
- **Coin-purchasable cosmetics remain in the game.** Adding paid cosmetics does not remove or price-gate items that were previously coin-purchasable. The coin economy must remain meaningful.

### 4.3 What Is Never Sold (Cosmetic or Otherwise)

- Coin multipliers
- Wider timing windows
- Auto-complete or skip for levels
- Hints or "guides" for specific levels
- Anything that makes the game easier for money

---

## 5. Coin Economy Balance

### 5.1 Earn Rates from GDD Section 7.1

| Action | Coins |
|---|---|
| Complete a level (first time) | 25 |
| Earn 1 star | 10 |
| Earn 2 stars | 25 |
| Earn 3 stars | 50 |
| Improve previous best star rating by 1 | 15 |
| Combo milestone (10/20/40/80) — first time per session | 5 each (max 20/session) |
| Sunbeam collected in Z1 (first 3 per session) | 3 each (max 9/session) |
| Community level first completion | 10 |
| Creator earn per completion of published level | 10 (cap 200/month/level) |

### 5.2 Session Earn Calculations

**Early progression (Zone 1, new player, 30-minute session):**

Zone 1 has 8 levels, each targeting 90–180 seconds of play. A 30-minute session at this stage allows approximately 8–12 level attempts (including retries).

Conservative estimate — player completes 6 new Zone 1 levels in 30 min, earning 2-star ratings:
- 6 first-time completions: 6 × 25 = 150 coins
- 6 levels at 2 stars: 6 × 25 = 150 coins
- Combo milestone (10-hit, first time): 5 coins
- 3 sunbeams collected: 3 × 3 = 9 coins
- **Total: ~314 coins in first 30-minute session**

Aggressive estimate — player completes all 8 Zone 1 levels and earns 3 stars on 4 of them:
- 8 first-time completions: 8 × 25 = 200 coins
- 4 levels at 3 stars: 4 × 50 = 200 coins
- 4 levels at 2 stars: 4 × 25 = 100 coins
- Combo milestones (10 + 20 for first time): 10 coins
- 3 sunbeams: 9 coins
- **Total: ~519 coins in 30-minute session**

**Mid progression (Zone 3, returning player, 30-minute session):**

Player is replaying levels for better stars and completing new Zone 3 levels:
- 3 new first-time completions: 3 × 25 = 75 coins
- 3 levels at 2 stars: 3 × 25 = 75 coins
- 2 star-improvement bonuses (1-star → 2-star): 2 × 15 = 30 coins
- Combo milestones: 10 coins
- **Total: ~190 coins in 30-minute session**

**Late progression (Zones 4–5, replay-focused, 30-minute session):**

Player has completed all zones, replaying for 3-star ratings:
- 4 star-improvement bonuses: 4 × 15 = 60 coins
- 2 three-star achievements: 2 × 50 = 100 coins
- Combo milestones: 15 coins
- **Total: ~175 coins in 30-minute session**

### 5.3 Spend Rate Validation

Coin cosmetic costs from GDD Section 7.2:

| Item | Cost | Earn Time (early) | Earn Time (mid/late) |
|---|---|---|---|
| Trail color variant | 50 coins | ~6 min | ~9 min |
| Character outfit/hat skin | 75–150 coins | ~9–18 min | ~13–26 min |
| Beat ring effect variant | 100 coins | ~12 min | ~17 min |
| Zone background palette | 150 coins | ~18 min | ~26 min |
| Custom UI theme | 200 coins | ~24 min | ~34 min |

**Verdict: Economy is well-balanced.** The cheapest cosmetic (50 coins / trail color) is achievable in under 10 minutes of active early play. The most expensive item (200 coins / UI theme) takes roughly 1.5–2 hours of casual mid-game play. This is within the target range of 1–3 hours stated in the design brief.

**No imbalances detected.** The earn rates do not create a situation where a player can max out all cosmetics too quickly (which would eliminate motivation) or where cosmetics feel unattainably grindy. 

**One advisory note:** The 200-coin UI theme is the highest-cost item. For a 6-year-old early in Zone 1 sessions, this represents roughly 40 minutes of focused play. This is acceptable — it is a prestige item, not a basic one. No adjustment recommended.

### 5.4 Important Economy Rules

- No coin purchases for real money (ever). Coins are earn-only.
- No daily login bonuses. Playing is the reward.
- No streak systems. Missing a day does not penalize the player.
- The coin earn system must remain fully functional for free players. Purchasing Full Reef or Creator Pass does not alter coin earn rates.

---

## 6. Price Tier Analysis

### 6.1 Full Reef at $2.99

**Why not $1.99:**
- $1.99 undervalues 16 levels of content. At $1.99, the per-level cost is $0.12, which is genuinely below the market value for quality mobile game content and signals low production quality.
- $1.99 is also the Creator Pass price. Having two products at the same price creates confusion about which is "more" — parents will ask "why are these the same price if one is bigger?"
- $2.99 for content expansion is an established and trusted price point in the kids' app market. Parents recognize it as "a small one-time upgrade" rather than "a significant purchase."

**Why not $4.99:**
- $4.99 for a kids' game content unlock is a significant parental commitment. While the content (16 levels, 1 character, future DLC access) arguably justifies it on value, it is above the psychological threshold many parents apply to kids' app upgrades.
- $4.99 invites comparison to "half a game" pricing, which triggers parental scrutiny and hesitation.
- $2.99 is below the threshold where most parents feel the need to deliberate. At $2.99, the decision is "should I spend less than a dollar per zone?" — that is an easy yes for parents who see their child enjoying the game.

**Why $2.99 specifically:**
- Falls on the standard App Store / Google Play pricing tier (Tier 3)
- Below $3, which is a psychological boundary for casual purchases
- Enables a meaningful bundle ($3.99 = $2.99 + $1.99 - $1.00 discount) that makes mathematical sense

**Future DLC commitment:** Full Reef buyers receive all future zone DLC at no additional cost. This is stated explicitly in the IAP description and must be honored contractually. This commitment is a significant trust signal — it assures parents they are not starting a long-tail purchase relationship. If future zones are added, they must be included automatically for Full Reef owners.

### 6.2 Creator Pass at $1.99

**Why $1.99:**
- The Creator Pass is an add-on for a specific use case (level creation and sharing), not a content expansion. Its audience is a subset of players — those who want to build.
- $1.99 is lower than Full Reef because it unlocks utility (creation tools) rather than play content (levels). Parents understand the hierarchy intuitively.
- $1.99 is the lowest standard price tier above $0.99 that signals "this is a real product, not a throwaway."
- Combined with Full Reef at $2.99, the bundle math ($3.99 vs $4.98) works cleanly with a $1.00 savings.

### 6.3 Platform Price Tier Mappings

| Product | Price USD | Google Play Tier | App Store Tier |
|---|---|---|---|
| Unlock Full Reef | $2.99 | Price Point 3 (USD 2.99) | Tier 3 |
| Creator Pass | $1.99 | Price Point 2 (USD 1.99) | Tier 2 |
| Reef Bundle | $3.99 | Price Point 4 (USD 3.99) | Tier 4 |

Future cosmetics at $0.99 would use Google Play Price Point 1 / App Store Tier 1.

### 6.4 Regional Pricing

Both Google Play Console and App Store Connect support automatic regional pricing based on the USD anchor price. Enable this for all three products at launch.

**Recommendation:** Use platform-automatic regional pricing initially. Do not manually customize regional prices for launch. Revisit after 90 days of sales data — if conversion rates in a specific major market (India, Brazil, Southeast Asia) are significantly below global average, consider manual regional pricing adjustments in those markets.

**Note on regional pricing and parental gate:** The parental gate must display the localized price pulled from the platform billing API, not a hardcoded USD price. This is specified in Section 3.2 and applies globally.

---

## 7. Prohibited Mechanics Confirmation

The following mechanics will **never** be added to Bubble Reef Rush. This list is reproduced from GDD Section 8.1 and extended with explicit rationale for the monetization context.

### 7.1 Energy and Lives Systems

**Never implement.** No "5 lives then wait 30 minutes." No "energy bar that depletes with play." No time gates on gameplay of any kind.

**Rationale:** Energy systems are designed to monetize frustration — they are the most common dark pattern in kids' games and the most commonly cited complaint in App Store reviews of games targeting this age group. More directly: they make the game less fun. A kid who wants to keep playing and cannot is a kid who has a bad time. Parents who see an energy gate become hostile to all monetization in the app, including the honest kind.

### 7.2 Countdown Timers and Limited-Time Offers

**Never implement.** No "offer expires in 4 hours." No "this item is available only today." No seasonal sales with end dates. No "limited edition" framing.

**Rationale:** Time pressure is a FOMO exploitation mechanic. Kids are developmentally susceptible to urgency — it feels real. Using countdown timers to drive purchase decisions from children is ethically indefensible regardless of legality. Beyond ethics: parents who see countdown timers in a kids' app will remove it immediately.

**What IS allowed:** Seasonal themes or visual updates tied to real-world events (e.g., a winter visual theme in December) — but only if the theme remains available permanently, not for a limited time.

### 7.3 Loot Boxes and Randomized Rewards

**Never implement.** No mystery boxes. No "spin the wheel." No randomized IAP rewards. No variable reward schedules for real money.

**Rationale:** Loot boxes are regulated as gambling in several jurisdictions and are being phased out of children's games through legislation in the EU, UK, and elsewhere. More fundamentally: if a child does not know what they are buying, they cannot make an informed purchasing decision and their parents cannot make an informed approval decision. All purchasable content must have a known, specific, listed description of exactly what is received.

**Coin system note:** The coin economy uses fixed-price items (50 coins = specific trail color). This is not a loot box. Every coin purchase is fully specified. This is compliant.

### 7.4 Advertising Networks

**Never implement.** No banner ads. No interstitial ads. No rewarded video ads ("watch a video to get coins"). No native ads. No partner promotions. No brand integrations.

**Rationale:** Ad networks in kids' apps create COPPA liability. Rewarded video ads are particularly problematic — they train children to equate watching advertising with in-game rewards, which is a manipulative behavioral pattern. The presence of any advertising in a kids' app signals to parents that the developer prioritizes revenue over the child's experience. The two one-time IAPs are the complete revenue model; advertising would undermine the trust that makes those IAPs viable.

### 7.5 Artificial Difficulty or Pay-to-Win

**Never implement.** The game must never become harder as a result of a player not paying. No mechanics that increase difficulty over time to frustrate free players into purchasing. No "free players get a handicap." No mechanics where paid players have any gameplay advantage.

**Rationale:** This is both an ethical rule and a legal/platform compliance rule. Google Play Families policy and Apple's age-appropriate design commitments explicitly prohibit pay-to-win mechanics in apps targeting children. Beyond compliance: this destroys player trust instantly and permanently when discovered.

### 7.6 Social Pressure Mechanics

**Never implement.** No "your friend bought this." No "X players purchased this today." No public leaderboards with strangers. No notifications about other players' achievements. No "invite friends to get coins."

**Rationale:** Social proof pressure is effective on adults and even more effective on children, who have strong peer belonging instincts. Using social mechanics to drive IAP in a children's game is a dark pattern. Leaderboards, if ever added, must show only known friends (opt-in social graph), not strangers, and must never trigger notifications.

### 7.7 Manipulation Through Visual/UX Design

**Never implement.** No asymmetric button sizing where the purchase button is larger or more prominent than dismiss. No guilt-trip dismiss text ("No thanks, I hate fun"). No pre-checked subscription opt-ins. No "are you sure you don't want this?" confirmation on dismiss. No misleading price displays (e.g., hiding the real price until the payment sheet).

**Rationale:** Dark patterns in UX are increasingly regulated under consumer protection law in multiple markets. For a kids' app, the standard is higher — the UX must be navigable by a child and reviewable by a parent without any question about intent.

---

*End of Monetization Specification v1.0*
