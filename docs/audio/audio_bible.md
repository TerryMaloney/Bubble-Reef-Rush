# Bubble Reef Rush — Audio Bible
**Role:** Audio Director (C-4)
**Game:** Bubble Reef Rush — Godot 4 Mobile Rhythm Runner, Ages 6–12
**Target Platform:** Android (varying speaker quality; all audio must translate well to tinny phone speakers)
**Audio Format:** OGG Vorbis
**Last Updated:** 2026-06-06

---

## SECTION 1 — MUSIC DIRECTION

This section defines every music track in the game: the 6 zone loops, their 6 speed-up variants, and the 4 extra tracks (menu, win, fail, editor). Each entry gives the developer enough information to evaluate generated tracks for quality and fit before dropping them into the project.

---

### Zone 1: Sunlit Shallows

**Track Name:** Sunlit Shallows Main Loop
**Filename:** `zone_1_sunlit_shallows.ogg`
**BPM:** 110
**Key/Mode:** C Major
**Instrumentation:** Steel pan drums (lead melody), marimba (counter-melody), synth bass (warm, slightly rounded), xylophone accents, bubbly synth arpeggios (sixteenth-note pattern), light shakers, acoustic ukulele strums on the 2 and 4 beats, soft choir "ooh" pad underneath.
**Mood:** Warm, sunny, and immediately welcoming — the feeling of stepping into shallow turquoise water on a perfect beach day. Bouncy and rhythmic, but never rushed; the player feels safe and happy from the first note.
**Loop Point:** 32.0 seconds (the track should be composed as a 32-second loop; the end of bar 16 at 110 BPM resolves back to the opening chord without a gap or click).
**Speed-Up Variant (`zone_1_sunlit_shallows_fast.ogg`):** Same arrangement at 120 BPM (approximately 9% faster). No new instruments added. The shaker pattern becomes slightly more prominent in the mix to reinforce the urgency. The bubbly arpeggios should feel more insistent but still cheerful — think "excited tropical fish" rather than "danger."

---

### Zone 2: Kelp Forest Canyon

**Track Name:** Kelp Forest Canyon Main Loop
**Filename:** `zone_2_kelp_forest.ogg`
**BPM:** 125
**Key/Mode:** E Dorian
**Instrumentation:** Nylon-string acoustic guitar (fingerpicked, dark and fluid), alto flute (breathy, mid-register melody), low marimba (bass pattern on roots), synth pad (slow-attack, watery shimmer, sits behind everything), plucked cello pizzicato (rhythmic pulse on beats 1 and 3), soft wind chime hits on phrase endings, subtle underwater whoosh ambient layer.
**Mood:** Mysterious and beautiful at the same time — the player feels like they are weaving through swaying kelp in filtered green light. There is a sense of gentle tension and discovery, but never fear; this is awe, not dread.
**Loop Point:** 30.72 seconds (exactly 64 bars at 125 BPM; the final chord is an open E5 that sustains into the loop start).
**Speed-Up Variant (`zone_2_kelp_forest_fast.ogg`):** 140 BPM (12% faster). Add a subtle hand drum (low bongo or frame drum) on the off-beats that was not present in the main loop — this gives the faster version a slightly more urgent propulsion. The flute melody may be slightly simplified (drop ornaments) so it still feels clean at the higher tempo.

---

### Zone 3: Shipwreck Alley

**Track Name:** Shipwreck Alley Main Loop
**Filename:** `zone_3_shipwreck_alley.ogg`
**BPM:** 135
**Key/Mode:** D Minor (with raised 6th — D Dorian coloring on melodic phrases)
**Instrumentation:** Accordion (lead melody, jaunty pirate feel), tenor recorder or tin whistle (counter-melody line), arco cello or low violin (rhythmic chugga pattern on off-beats), hand drum / bodhrán (driving eighth-note pulse), orchestral snare drum (snappy, on beats 2 and 4), pizzicato double bass (walking bass line), ship bell SFX hit every 8 bars, short brass stab chord accent on bar 4 of each phrase.
**Mood:** Exciting pirate-adventure energy — the player is a brave fish explorer navigating a spooky but thrilling shipwreck, like a children's adventure movie score. The minor key adds drama, but the accordion and tin whistle keep it playful and fun, not frightening.
**Loop Point:** 28.44 seconds (exactly 64 bars at 135 BPM; resolves to a root D minor chord that feeds back into the opening riff).
**Speed-Up Variant (`zone_3_shipwreck_alley_fast.ogg`):** 152 BPM (approximately 12.5% faster). The brass stabs become more frequent — every 2 bars instead of every 4. The snare drum adds a short roll fill at phrase endings to push the energy. Otherwise the same arrangement; the extra speed does all the work.

---

### Zone 4: Volcanic Vent Fields

**Track Name:** Volcanic Vent Fields Main Loop
**Filename:** `zone_4_volcanic_vent.ogg`
**BPM:** 155
**Key/Mode:** F# Minor (Aeolian)
**Instrumentation:** Distorted synth bass (heavy, pulsing, sub-register), industrial percussion (metallic hit on beat 1, electronic clap on beat 3, 16th-note hi-hat pattern), lead synth with pitch-bent wail (mid-register, slightly aggressive but still melodic), arpeggiated synth sequence (driving eighth-notes in F# minor), low brass stabs (syncopated, every 3 bars), eerie synth whoosh sweeps between phrases, underwater bubble "blorp" accent (from game SFX library, layered musically).
**Mood:** Urgent, industrial, and exciting — the player is racing through vents of superheated water and glowing magma, and the music makes them feel like a hero in an action sequence. Dark and intense but still clearly a kids' game score, not a horror soundtrack; the melody always wins over the heaviness.
**Loop Point:** 30.97 seconds (exactly 80 bars at 155 BPM; ends on a synth swell that resolves to the opening bass hit).
**Speed-Up Variant (`zone_4_volcanic_vent_fast.ogg`):** 174 BPM (approximately 12% faster). The arpeggio sequence tightens; consider switching the 16th-note hi-hat to a tremolo roll effect for added intensity. The lead synth melody may drop an octave in places to stay clean at this speed. Still must sound thrilling, not chaotic — clarity matters on phone speakers.

---

### Zone 5: Twilight Trench

**Track Name:** Twilight Trench Main Loop
**Filename:** `zone_5_twilight_trench.ogg`
**BPM:** Variable — starts at 80 BPM, reaches 140 BPM by the end of the generated clip (see note below)
**Key/Mode:** A Minor (natural, shifting toward A Phrygian in the intense sections)
**Instrumentation:** Opening section (80–100 BPM): solo cello melody (bowed, expressive), deep string pad (low, vast, reverb-heavy), vibraphone single notes (sparse, resonating), distant whale-call synth. Middle build (100–120 BPM): full string ensemble enters, soft orchestral snare roll, harp arpeggios, choir "ah" pad rising. Climax surge (120–140 BPM): full orchestra tutti with brass melody doubling strings, driving timpani, synth bass reinforcing low end, all previous elements at maximum intensity.
**Mood (opening):** Vast, beautiful, and slightly awe-inspiring — the player has descended into deep ocean where the light barely reaches. The opening feels like floating in space, beautiful and enormous.
**Mood (climax):** Heroic and exhilarating — the music surges to match the increasing game speed, turning the awe into triumph. A child should feel genuinely epic in this moment, not afraid.
**Loop Point:** Because this track has built-in BPM automation, the game code handles it differently from other zones. The generated audio clip should be approximately 90–120 seconds long (not a short loop) and be designed to NOT loop — it plays once per run of Zone 5. The "loop" in the manifest is set to the full track length. See Section 4 for implementation notes.
**Speed-Up Variant (`zone_5_twilight_trench_fast.ogg`):** The speed-up variant for Zone 5 is the climax section (120–140 BPM) isolated as a 30-second standalone loop, starting at full intensity. This is used if the player enters a speed zone mid-zone-5 and the track needs to jump to the intense section immediately.

---

### Zone 6: Crystal Caves (Secret Zone)

**Track Name:** Crystal Caves Main Loop
**Filename:** `zone_6_crystal_caves.ogg`
**BPM:** 174
**Key/Mode:** B Major (bright, crystalline, unexpected major key at this intensity — feels magical rather than aggressive)
**Instrumentation:** Music box lead melody (delicate, high-register, crystal-clear), harpsichord ornament runs (rapid, sparkling 32nd-note passages), tuned glass harmonica or crystal singing bowl pad (ethereal, shimmering), fast synth arpeggio (ascending and descending 16th-note patterns in B major), pizzicato string ensemble (tight, fast, rhythmically driving), orchestral glockenspiel doubling the music box melody, synth "sparkle" accent (short, pitched high, every two beats), driving electronic kick drum (four-on-the-floor at 174 BPM to keep the energy danceable).
**Mood:** Prismatic, magical, and breathtaking — this is the hidden reward zone, and the music must feel like discovering a room full of jewels and light. It should sound genuinely special and different from every other zone, the musical equivalent of "you found the secret."
**Loop Point:** 27.59 seconds (exactly 80 bars at 174 BPM; the harpsichord run at the end of bar 80 resolves to the opening music box note of bar 1 seamlessly).
**Speed-Up Variant (`zone_6_crystal_caves_fast.ogg`):** 192 BPM (approximately 10% faster). The music box melody may be replaced by a slightly more synth-forward lead at this speed to stay articulate on small speakers. The harpsichord runs become shorter (cut from 32nd to 16th notes). The kick drum, arpeggio, and sparkle accents carry the energy. Must still feel magical, not frantic.

---

### Extra Track: Main Menu

**Track Name:** Main Menu Theme
**Filename:** `menu_main.ogg`
**BPM:** 108
**Key/Mode:** G Major
**Instrumentation:** Ukulele strumming (warm, friendly, chord-based), steel pan melody (simple, memorable, 8-bar phrase that repeats), marimba bass notes (light, on the root and fifth), bubbly synth arpeggios (quiet, background texture), gentle ocean wave ambient bed (very low in mix, barely audible), soft glockenspiel accent on the first beat of every 4th bar.
**Mood:** Instantly welcoming and wonder-filled — this is the first thing a child hears when they open the app, and it must make them immediately excited to play. Feels like summer vacation at the beach, friendly and unhurried.
**Loop Point:** 29.63 seconds (exactly 53.3 bars — use 32 bars at 108 BPM = 17.78 seconds for a shorter loop option if the generator cannot make 29 seconds; 32 bars is preferred minimum for menu music).
**Speed-Up Variant:** None needed for menu.

---

### Extra Track: Level Complete / Win Jingle

**Track Name:** Level Complete Jingle
**Filename:** `jingle_win.ogg`
**BPM:** 130
**Key/Mode:** C Major
**Instrumentation:** Brass fanfare (short, 3-note ascending phrase), glockenspiel trill, synth "shimmer" sweep upward, marimba resolution chord, brief burst of cartoon-style "twinkle" notes (like stars appearing), ends on a held G major chord with reverb tail.
**Mood:** Triumphant and joyful — the player succeeded and deserves a musical hug. Think Saturday morning cartoon victory sting, warm and affirming.
**Loop Point:** N/A — this is a one-shot jingle, approximately 3–4 seconds long. Do not loop.
**Speed-Up Variant:** None.

---

### Extra Track: Level Fail / Retry Jingle

**Track Name:** Level Fail Jingle
**Filename:** `jingle_fail.ogg`
**BPM:** 90
**Key/Mode:** A Minor
**Instrumentation:** Tuba or low trombone "wah-wah" descending phrase (2 notes, sliding down), cartoon woodblock knock, muted trumpet "sad trombone" effect, ends on a minor chord with a wobble. Should sound comedic and sympathetic, not punishing.
**Mood:** Gently silly and encouraging — the player missed, but the music says "oops, try again!" not "you failed." Think Looney Tunes sympathy sting. Kids should laugh slightly, not feel bad.
**Loop Point:** N/A — one-shot jingle, approximately 2–3 seconds long. Do not loop.
**Speed-Up Variant:** None.

---

### Extra Track: Level Editor Ambient

**Track Name:** Level Editor Ambient Loop
**Filename:** `ambient_editor.ogg`
**BPM:** 90 (very relaxed, mostly ambient — the BPM is a loose guide for any rhythmic elements)
**Key/Mode:** D Major (open, spacious)
**Instrumentation:** Slow, filtered piano chords (one chord every 4 beats, lots of sustain pedal), gentle underwater whoosh texture (looping), occasional single vibraphone note (every 8–12 seconds, semi-random feel), slow synth pad (D major open-fifth drone, fades in and out slowly), distant whale-song synth (very quiet, long attack and release), no percussion.
**Mood:** Calm, creative, and focused — the player is building their own level and needs music that supports concentration without distracting. Feels like peaceful daydreaming underwater. Should never demand the player's attention.
**Loop Point:** 60.0 seconds (ambient tracks benefit from longer loops to avoid obvious repetition; 60-second loop at this density should feel seamless).
**Speed-Up Variant:** None.

---

## SECTION 2 — AI MUSIC GENERATOR PROMPTS

These are complete, copy-paste-ready prompts for Suno AI and Udio. Use whichever platform you have access to. Both prompts aim for the same sonic result. For each track, try at least 3 generations and pick the one that best matches the direction in Section 1.

**General tips before you start:**
- In Suno AI, paste the content inside `[ ]` into the Style field. Leave the Lyrics field blank or type "(Instrumental)" to avoid vocals.
- In Udio, paste the full paragraph into the main prompt field and select "No vocals / Instrumental" if the option exists.
- Generate at 2x the length you need, then trim, so you have options for the loop point.
- Reject any generation that has speech, singing, or obvious intro/outro (fade-in/fade-out) — you need clean loops.

---

```
TRACK: zone_1_sunlit_shallows.ogg
SUNO PROMPT:
[upbeat kids game soundtrack, tropical underwater theme, steel pan drums lead melody, marimba counter-melody, bubbly synth arpeggios, warm synth bass, ukulele strums on backbeat, xylophone accents, light shaker percussion, 110 BPM, C major, cheerful and bouncy, Saturday morning cartoon energy, no lyrics, no vocals, seamless loop, children's mobile game music, bright and warm, sunshine underwater]

UDIO PROMPT (alternative):
Upbeat tropical underwater children's game music at 110 BPM in C major. Steel pan drums carry the lead melody with marimba providing a counter-melody. Bubbly synth arpeggios run in the background. Warm rounded synth bass holds the low end. Ukulele strums on beats 2 and 4. Xylophone accents and light shakers fill the rhythm. Bright, cheerful, bouncy. Saturday morning cartoon energy. No vocals. No lyrics. Designed to loop seamlessly. Suitable for a kids' mobile rhythm game about swimming through colorful ocean zones.

STYLE TAGS: children's game music, tropical, underwater, instrumental, upbeat, loop-friendly, steel drums, marimba, 110 BPM
```

---

```
TRACK: zone_1_sunlit_shallows_fast.ogg
SUNO PROMPT:
[upbeat kids game soundtrack, tropical underwater theme, steel pan drums lead melody, marimba counter-melody, bubbly synth arpeggios, warm synth bass, ukulele strums on backbeat, prominent shakers on off-beats, 120 BPM, C major, excited and urgent but still cheerful, faster than normal but not scary, no lyrics, no vocals, seamless loop, children's mobile game music, speed zone variant, bright tropical energy]

UDIO PROMPT (alternative):
Upbeat tropical underwater children's game music at 120 BPM in C major — a faster speed-zone variant. Steel pan drums and marimba lead melody plays urgently but stays cheerful. Bubbly synth arpeggios are more insistent. Shakers are prominent on every off-beat adding urgency. No change in instrumentation from the base track, just faster and slightly more driven. No vocals. Seamless loop. Children's mobile rhythm game speed burst section.

STYLE TAGS: children's game music, tropical, underwater, instrumental, upbeat, fast, speed zone, 120 BPM, loop-friendly
```

---

```
TRACK: zone_2_kelp_forest.ogg
SUNO PROMPT:
[mysterious kids game music, underwater kelp forest, nylon string acoustic guitar fingerpicking, breathy alto flute melody, low marimba bass, watery synth pad shimmer, pizzicato cello pulse, wind chime accents, 125 BPM, E dorian mode, mysterious and beautiful, awe-inspiring not scary, dappled green light mood, no lyrics, no vocals, seamless loop, children's mobile game, emerald underwater adventure]

UDIO PROMPT (alternative):
Mysterious yet beautiful children's game music for an underwater kelp forest zone at 125 BPM in E Dorian. Nylon-string acoustic guitar provides fingerpicked texture. A breathy alto flute carries the melody. Low marimba establishes the bass pattern. A slow-attack watery synth pad shimmers behind everything. Pizzicato cello pulses on beats 1 and 3. Wind chimes accent phrase endings. The mood is awe and gentle discovery — mysterious but never frightening. No vocals. Seamless loop. Kids' mobile game.

STYLE TAGS: children's game music, underwater, kelp forest, mysterious, instrumental, dorian mode, flute, acoustic guitar, loop-friendly, 125 BPM
```

---

```
TRACK: zone_2_kelp_forest_fast.ogg
SUNO PROMPT:
[mysterious kids game music, underwater kelp forest speed zone, nylon string acoustic guitar fingerpicking, breathy alto flute melody, low marimba bass, watery synth pad shimmer, bongo hand drum off-beat pulse added, 140 BPM, E dorian mode, urgent and mysterious, faster than base track, hand drum drives the energy, no lyrics, no vocals, seamless loop, children's mobile game, faster kelp forest variant]

UDIO PROMPT (alternative):
Faster variant of the kelp forest children's game music at 140 BPM in E Dorian. Same instrumentation as the base: nylon guitar, alto flute, low marimba, watery synth pad. A hand drum (low bongo) is now added on off-beats, providing the urgency the higher tempo needs. The flute melody is slightly simplified — fewer ornaments. The overall mood is still mysterious and beautiful but now urgent and propulsive. No vocals. Seamless loop. Kids' mobile rhythm game speed zone.

STYLE TAGS: children's game music, underwater, kelp forest, mysterious, faster, hand drum, instrumental, 140 BPM, loop-friendly
```

---

```
TRACK: zone_3_shipwreck_alley.ogg
SUNO PROMPT:
[pirate adventure kids game music, underwater shipwreck zone, accordion lead melody, tin whistle counter-melody, arco cello chugga rhythm, bodhran hand drum driving pulse, orchestral snare beats 2 and 4, pizzicato double bass walking bass, ship bell accent every 8 bars, short brass stab chords, 135 BPM, D minor dorian coloring, exciting pirate adventure, brave and jaunty, kids' action movie score energy, no lyrics, no vocals, seamless loop, children's mobile game]

UDIO PROMPT (alternative):
Exciting pirate adventure children's game music for an underwater shipwreck zone at 135 BPM in D minor with Dorian coloring. Accordion carries the lead melody with a jaunty nautical character. Tin whistle or recorder provides the counter-melody. A bodhrán or frame drum drives an eighth-note pulse. Orchestral snare snaps on beats 2 and 4. Pizzicato double bass walks the bass line. Ship bell accents every 8 bars. Short brass stab chords punctuate phrase endings. Brave, adventurous, exciting — like a children's pirate movie score. No vocals. Seamless loop.

STYLE TAGS: children's game music, pirate, shipwreck, underwater, adventure, accordion, tin whistle, orchestral, 135 BPM, loop-friendly
```

---

```
TRACK: zone_3_shipwreck_alley_fast.ogg
SUNO PROMPT:
[pirate adventure kids game music, underwater shipwreck speed zone, accordion lead melody, tin whistle counter-melody, arco cello chugga rhythm, bodhran hand drum driving pulse, orchestral snare with roll fills at phrase ends, pizzicato double bass walking bass, brass stabs every 2 bars increased frequency, 152 BPM, D minor, fast and exciting, speed zone energy, more urgent than base track, no lyrics, no vocals, seamless loop, children's mobile game]

UDIO PROMPT (alternative):
Fast speed-zone variant of the pirate shipwreck children's game music at 152 BPM in D minor. Same instrumentation: accordion, tin whistle, cello, bodhrán, snare, double bass. Brass stabs now appear every 2 bars instead of every 4. The snare adds short roll fills at phrase endings to push energy. The faster tempo and more frequent brass hits make this feel like the climax of a pirate chase. Still fun and brave, not scary. No vocals. Seamless loop. Kids' mobile rhythm game speed burst.

STYLE TAGS: children's game music, pirate, shipwreck, fast, speed zone, brass stabs, 152 BPM, loop-friendly
```

---

```
TRACK: zone_4_volcanic_vent.ogg
SUNO PROMPT:
[action kids game music, underwater volcanic vent zone, distorted synth bass pulsing sub, industrial metallic percussion, electronic clap on beat 3, 16th note hi-hat pattern, lead synth wailing melody F# minor, driving eighth-note arpeggio sequence, low brass syncopated stabs, eerie synth whoosh sweeps, 155 BPM, F sharp minor, urgent and exciting, industrial electronic underwater, not scary still kids game energy, no lyrics, no vocals, seamless loop, children's mobile game, action sequence feel]

UDIO PROMPT (alternative):
Urgent action music for an underwater volcanic vent zone in a children's game at 155 BPM in F# minor. A heavy pulsing distorted synth bass anchors the low end. Industrial metallic percussion hits on beat 1. Electronic clap on beat 3. A fast 16th-note hi-hat pattern drives the energy. A pitch-bent lead synth wails a melodic line over the top. A driving eighth-note arpeggio sequence pushes through F# minor. Low syncopated brass stabs appear every 3 bars. Eerie synth whoosh sweeps connect sections. Intense and exciting, but still melodic and appropriate for children. No vocals. Seamless loop.

STYLE TAGS: children's game music, volcanic, industrial, electronic, action, F# minor, synth bass, 155 BPM, loop-friendly, underwater
```

---

```
TRACK: zone_4_volcanic_vent_fast.ogg
SUNO PROMPT:
[action kids game music, underwater volcanic vent speed zone, distorted synth bass pulsing sub, industrial metallic percussion, tremolo hi-hat roll replacing 16th note pattern, lead synth melody drops octave for clarity, driving eighth-note arpeggio tighter, low brass syncopated stabs, eerie synth whoosh sweeps, 174 BPM, F sharp minor, maximum urgency, intense electronic kids game, no lyrics, no vocals, seamless loop, children's mobile game speed burst, thrilling not chaotic]

UDIO PROMPT (alternative):
Maximum-urgency speed-zone variant of the volcanic vent children's game music at 174 BPM in F# minor. Same heavy synth bass and industrial percussion. The 16th-note hi-hat is replaced by a tremolo roll effect for added intensity at this higher tempo. The lead synth melody drops an octave in places to stay articulate on small phone speakers. The arpeggio sequence is tighter and faster. Must remain thrilling and clear, not chaotic. No vocals. Seamless loop. Kids' mobile rhythm game.

STYLE TAGS: children's game music, volcanic, industrial, electronic, speed zone, 174 BPM, loop-friendly, fast, intense
```

---

```
TRACK: zone_5_twilight_trench.ogg
SUNO PROMPT:
[epic orchestral kids game music, deep ocean twilight trench, starts slow builds to full orchestra, opening solo cello melody 80 BPM, deep reverb string pad, vibraphone sparse notes, distant whale synth, builds through 100 BPM with full strings and harp, climaxes at 140 BPM with brass melody choir and timpani, A minor to A phrygian, vast and beautiful opening becomes heroic climax, 90 to 120 seconds total length, children's adventure game, no loops needed full track, no lyrics no vocals, epic cinematic underwater journey]

UDIO PROMPT (alternative):
A long-form epic orchestral piece for a children's game deep ocean zone, approximately 90–120 seconds, with built-in tempo acceleration. Opens at 80 BPM with a solo cello melody over a deep reverbed string pad, sparse vibraphone notes, and distant whale-call synth — vast and beautiful. Builds through 100 BPM as full strings, harp arpeggios, and soft snare roll enter. Climaxes at 140 BPM with full orchestra: brass doubling the string melody, choir, driving timpani, and synth bass reinforcing the low end. A minor throughout, shifting toward Phrygian in the climax. Heroic, epic, child-safe. No vocals. One-shot (not looped).

STYLE TAGS: orchestral, cinematic, epic, children's game, underwater, A minor, tempo build, strings, brass, choir, 80-140 BPM, no loop
```

---

```
TRACK: zone_5_twilight_trench_fast.ogg
SUNO PROMPT:
[epic orchestral kids game music, deep ocean twilight trench speed zone, full orchestra at maximum intensity, brass melody over strings, driving timpani, choir ah pad, synth bass low end, 140 BPM, A minor phrygian, heroic and exhilarating, climax section isolated as standalone loop, children's game speed zone, no intro no buildup starts at full intensity, no lyrics no vocals, seamless 30 second loop]

UDIO PROMPT (alternative):
A 30-second loopable orchestral piece representing the climax section of a deep ocean zone in a children's game at 140 BPM in A Phrygian. Starts immediately at full intensity: brass doubling string melody, driving timpani, choir "ah" pad, synth bass on the low end. No intro or build-up — this is the speed-zone variant that triggers at maximum orchestra. Heroic, exhilarating, child-appropriate. No vocals. Designed to loop seamlessly. Kids' mobile rhythm game.

STYLE TAGS: orchestral, cinematic, epic, children's game, speed zone, 140 BPM, brass, strings, chorus, loop-friendly
```

---

```
TRACK: zone_6_crystal_caves.ogg
SUNO PROMPT:
[magical secret zone kids game music, crystal caves, music box high register lead melody, harpsichord rapid 32nd note runs sparkling, crystal singing bowl ethereal pad, fast ascending descending synth arpeggio 16th notes, pizzicato strings tight and fast, glockenspiel doubling music box, synth sparkle accent every two beats, four-on-the-floor electronic kick drum, 174 BPM, B major, magical and prismatic, hidden treasure room energy, feels special and rare, no lyrics no vocals, seamless loop, children's mobile game secret zone]

UDIO PROMPT (alternative):
Magical children's game music for a secret crystal cave zone at 174 BPM in B major. A delicate high-register music box carries the lead melody, doubled by glockenspiel. Harpsichord plays rapid sparkling 32nd-note ornament runs. A crystal singing bowl or glass harmonica provides an ethereal shimmering pad. Fast ascending and descending 16th-note synth arpeggios drive forward momentum. Pizzicato strings provide tight rhythmic energy. A synth sparkle accent fires every two beats. A four-on-the-floor kick drum at 174 BPM keeps the energy danceable. B major throughout — bright, prismatic, magical. The music must feel genuinely special, like discovering a hidden treasure room. No vocals. Seamless loop.

STYLE TAGS: children's game music, secret zone, crystal, magical, music box, harpsichord, B major, 174 BPM, loop-friendly, fantasy
```

---

```
TRACK: zone_6_crystal_caves_fast.ogg
SUNO PROMPT:
[magical secret zone kids game music, crystal caves speed variant, synth lead melody replacing music box at this speed, harpsichord 16th note runs shorter passages, fast ascending descending synth arpeggio driving, pizzicato strings tight and fast, glockenspiel accents, synth sparkle every two beats, four-on-the-floor electronic kick drum, 192 BPM, B major, magical and prismatic but faster, urgently magical not frantic, no lyrics no vocals, seamless loop, children's mobile game crystal cave speed burst]

UDIO PROMPT (alternative):
Speed-zone variant of the crystal caves children's game music at 192 BPM in B major. At this tempo the music box lead is replaced by a slightly more synth-forward lead instrument that stays articulate on small speakers. Harpsichord ornament runs are shortened from 32nd to 16th notes. The synth arpeggio, pizzicato strings, sparkle accents, and four-on-the-floor kick drum from the base track all remain. Must still feel magical and special, not chaotic. No vocals. Seamless loop. Kids' mobile rhythm game.

STYLE TAGS: children's game music, crystal, magical, speed zone, synth lead, 192 BPM, loop-friendly, B major, fast
```

---

```
TRACK: menu_main.ogg
SUNO PROMPT:
[welcoming kids game menu music, tropical ocean theme, ukulele strumming warm chords, steel pan simple memorable melody 8 bar phrase, marimba bass roots and fifths, bubbly synth arpeggios background texture, gentle ocean wave ambient bed, glockenspiel accent every 4 bars, 108 BPM, G major, friendly and wonder-filled, summer vacation beach feeling, inviting and unhurried, no lyrics no vocals, seamless loop, children's mobile game main menu, first impression of the game]

UDIO PROMPT (alternative):
Warm and welcoming children's mobile game menu music at 108 BPM in G major. Ukulele strums friendly chords throughout. A steel pan carries a simple memorable 8-bar melody. Marimba provides light bass notes on roots and fifths. Bubbly synth arpeggios add a quiet sparkling texture in the background. A very gentle ocean wave ambient bed sits almost inaudibly behind everything. Glockenspiel accents the first beat of every 4th bar. The overall feeling is summer vacation at the beach — immediately exciting, friendly, and welcoming. No vocals. Seamless loop. This is the first music a child hears when opening the app.

STYLE TAGS: children's game music, menu theme, tropical, ukulele, steel pan, G major, 108 BPM, welcoming, loop-friendly
```

---

```
TRACK: jingle_win.ogg
SUNO PROMPT:
[victory jingle kids game, 3 second triumphant sting, brass fanfare ascending 3 note phrase, glockenspiel trill, synth shimmer sweep upward, marimba resolution chord, cartoon twinkle star notes, ends on held G major reverb tail, 130 BPM, C major, triumphant and joyful, Saturday morning cartoon victory sting, warm and affirming, no lyrics no vocals, one shot not looped, children's mobile game level complete sound]

UDIO PROMPT (alternative):
A short 3–4 second triumphant victory jingle for a children's mobile game at 130 BPM in C major. Begins with a 3-note ascending brass fanfare. Glockenspiel trill follows immediately. A synth shimmer sweeps upward. Marimba plays a resolution chord. Brief cartoon-style "twinkle" notes sparkle like stars appearing. Ends on a held G major chord with natural reverb tail. Warm, joyful, affirming. Saturday morning cartoon victory sting energy. No vocals. One-shot — does not loop.

STYLE TAGS: victory jingle, children's game, one-shot, brass fanfare, C major, triumphant, cartoon, 130 BPM
```

---

```
TRACK: jingle_fail.ogg
SUNO PROMPT:
[fail jingle kids game, 2 to 3 second comedic sympathy sting, tuba descending wah-wah 2 notes sliding down, cartoon woodblock knock, muted trumpet sad trombone effect, ends on minor chord with wobble, 90 BPM, A minor, comedic and sympathetic not punishing, looney tunes sympathy energy, kids should laugh not feel bad, no lyrics no vocals, one shot not looped, children's mobile game retry sound]

UDIO PROMPT (alternative):
A short 2–3 second comedic fail jingle for a children's mobile game at 90 BPM in A minor. A tuba or low trombone plays a 2-note descending "wah-wah" sliding phrase. A cartoon woodblock knock punctuates. A muted trumpet delivers a classic "sad trombone" effect. Ends on a minor chord with a slight pitch wobble. Comedic and sympathetic — sounds like "oops, try again!" not like a punishment. Looney Tunes sympathy sting energy. Children should find it slightly funny, not discouraging. No vocals. One-shot — does not loop.

STYLE TAGS: fail jingle, children's game, one-shot, comedic, sad trombone, A minor, cartoon, sympathetic, 90 BPM
```

---

```
TRACK: ambient_editor.ogg
SUNO PROMPT:
[calm ambient kids game level editor music, slow filtered piano chords one chord every 4 beats sustain pedal, gentle underwater whoosh texture looping, occasional single vibraphone note every 8 to 12 seconds, slow synth D major open fifth drone, distant whale song synth very quiet, no percussion, 90 BPM loose, D major, calm and creative and focused, peaceful daydreaming underwater, supports concentration without distraction, no lyrics no vocals, 60 second seamless loop, children's mobile game level builder ambient]

UDIO PROMPT (alternative):
Calm ambient music for the level editor of a children's mobile game. Very slow and peaceful, approximately 90 BPM with a loose ambient feel. Slow filtered piano plays one chord every 4 beats with full sustain pedal. A gentle underwater whoosh texture loops continuously in the background. Occasional single vibraphone notes appear every 8–12 seconds with long resonance. A slow synth drone on a D major open fifth fades in and out. Distant whale-song synth is nearly inaudible. No percussion at all. D major. Calm, creative, and focused — supports concentration without demanding attention. No vocals. 60-second seamless loop. Children's game.

STYLE TAGS: ambient, level editor, children's game, calm, underwater, D major, piano, vibraphone, no drums, loop-friendly, 60 seconds
```

---

## SECTION 3 — SFX CATALOG

All SFX should be mixed at a level where they sit clearly above the music on phone speakers without overwhelming it. Target peak level: −6 dBFS for HIGH priority, −9 dBFS for MED, −12 dBFS for LOW. Stereo width should be minimal (near-mono) so sounds are audible on mono phone speakers.

| Event Name | Trigger | Character Description | Duration (ms) | Loops? | Priority |
|---|---|---|---|---|---|
| `player_dive` | Player swipes/taps to dive downward | A smooth underwater "whoosh" that swoops downward in pitch — like a dolphin diving. Starts with a light water entry "shlick" at the front, then a falling pitch sweep. Clean, not splashy. | 250 | No | HIGH |
| `player_float` | Player releases to float upward | The inverse of player_dive: a gentle rising pitch sweep, like a bubble rising quickly. Light and airy, ends with a soft "bloop" at the top. | 220 | No | HIGH |
| `player_hit_obstacle` | Player collides with any obstacle | A dull underwater "thud" — like bumping into a rock underwater. Includes a brief rattle/vibration resonance after the impact. Not painful-sounding, more cartoonish than realistic. | 350 | No | HIGH |
| `player_death` | Player health reaches zero / run ends | A descending bubbly "glug-glug-glug" sequence (3 notes descending, each a soft bubble pop) followed by a low underwater rumble fading out. Comedic and sympathetic rather than dramatic. Total: 5 descending pops then rumble tail. | 1800 | No | HIGH |
| `perfect_timing` | Rhythm hit within ±20ms of beat | A bright, clean "ding" with a short synth sparkle tail — like a small silver bell. Crisp and satisfying. Sits high in frequency (around 3–5kHz) so it cuts through the music. | 180 | No | HIGH |
| `good_timing` | Rhythm hit within ±60ms of beat | Similar to perfect_timing but slightly softer and slightly lower in pitch — same bell character but less brilliant. The player should immediately perceive it as "good but not perfect." | 160 | No | HIGH |
| `miss_timing` | Rhythm hit outside timing window | A quiet, muffled "blorp" — like a failed bubble that fizzles instead of popping. Low energy, slightly dejected. Must not be loud or startling, just a soft "nope." | 120 | No | HIGH |
| `combo_start` | Player achieves 5 consecutive good/perfect hits | An ascending three-note musical sting (D–F#–A, a D major arpeggio) played on a synth chime. Short, bright, celebratory. Signals to the player that something good is happening. | 400 | No | MED |
| `combo_break` | Combo counter resets due to miss | A short descending two-note chime (same synth tone as combo_start but going down), followed by the miss_timing "blorp." The descending notes signal the combo ended. | 280 | No | MED |
| `coin_collect` | Player passes over a coin/collectible | A classic arcade-style short "ping" — clean sine-wave tone at around 800Hz, very short sustain. Feels rewarding without being distracting. Multiple rapid collects should stack without becoming noise. | 80 | No | MED |
| `level_complete` | Player crosses the finish line of a level | A 2-second ascending synth sweep followed by a bright chord burst (all instruments from the zone track, hitting a big major chord simultaneously). Feels like crossing a finish line. | 2200 | No | HIGH |
| `level_fail` | Player dies or time-expires on a level | Plays the jingle_fail.ogg track (cross-reference to music assets). The SFX bus plays this, not the music bus, so it cuts the music instantly. | 2500 | No | HIGH |
| `character_select` | Player taps a character portrait in the selection screen | A short playful "bwip" — like a cartoon character popping into view. High-pitched, very short, slightly rubbery. Each different character could use a slightly different pitch variant (export 3 pitch variants: character_select_1.ogg, character_select_2.ogg, character_select_3.ogg). | 100 | No | MED |
| `button_tap` | Any UI button press | A soft, clean "click" — like a plastic bubble being tapped with a fingernail. Very short, neutral in pitch, not distracting. Should feel tactile and satisfying without drawing attention. | 60 | No | MED |
| `zone_unlock` | Player unlocks a new ocean zone | A 3-second magical fanfare: rising synth arpeggio sweep (2 seconds) that resolves into a bright orchestral chord with sparkle overlay. More elaborate than combo_start. Rewards the player's progress. | 3000 | No | HIGH |
| `achievement_unlock` | An in-game achievement is awarded | A 2-second notification sting: bright two-note ascending chime (a musical fifth, e.g. C–G) followed by a warm synth pad swell. Distinct from zone_unlock — softer and more personal, like a small celebration. | 2000 | No | MED |
| `build_mode_place_obstacle` | Player places an obstacle in the level editor | A satisfying soft "clunk" — like setting a wooden block gently on a table. Thump-y, grounded, short. Signals successful placement. | 120 | No | MED |
| `build_mode_delete` | Player deletes an obstacle in the level editor | A light "pop" — like a soap bubble bursting. Lighter and higher than the place sound. Signals removal clearly without being harsh. | 90 | No | MED |
| `level_publish` | Player taps the publish/share button for their level | A 2.5-second sound: starts with a "whoosh" (like sending something upward), transitions into three ascending synth chimes (do-mi-sol), ends with a crowd-cheer sample or "yay" synth stab. Celebratory and communal — the player just shared something with the world. | 2500 | No | HIGH |

---

## SECTION 4 — AUDIO IMPLEMENTATION SPEC

### 4.1 Godot 4 AudioServer — Beat Sync (Pseudocode)

The game needs to know the position of the current beat so obstacles can be timed to music and visual effects can pulse on-beat.

```gdscript
# BeatManager.gd — Autoload singleton
# Attach to: Project > Project Settings > Autoload

extends Node

signal beat_fired(beat_number: int)
signal half_beat_fired(beat_number: float)

var current_bpm: float = 110.0
var beat_duration_sec: float = 0.0   # seconds per beat
var next_beat_time: float = 0.0      # AudioServer time of the next beat
var beat_count: int = 0
var user_offset_sec: float = 0.0     # populated from user settings

@onready var music_player: AudioStreamPlayer = $MusicPlayer

func start_zone(bpm: float, stream: AudioStream) -> void:
    current_bpm = bpm
    beat_duration_sec = 60.0 / bpm
    music_player.stream = stream
    music_player.play()
    # Schedule the first beat slightly in the future so we don't miss it
    next_beat_time = AudioServer.get_time_since_last_mix() + beat_duration_sec + user_offset_sec
    beat_count = 0

func _process(_delta: float) -> void:
    # AudioServer.get_time_since_last_mix() gives low-latency clock
    var now: float = AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
    while now >= next_beat_time:
        beat_count += 1
        emit_signal("beat_fired", beat_count)
        # Also fire a half-beat signal for 8th-note precision
        call_deferred("_fire_half_beat")
        next_beat_time += beat_duration_sec

func _fire_half_beat() -> void:
    await get_tree().create_timer(beat_duration_sec * 0.5).timeout
    emit_signal("half_beat_fired", beat_count + 0.5)
```

**How obstacles use BeatManager:**
```gdscript
# ObstacleSpawner.gd
func _ready() -> void:
    BeatManager.beat_fired.connect(_on_beat)

func _on_beat(beat_number: int) -> void:
    if beat_number % 4 == 0:   # spawn every 4 beats
        spawn_obstacle()
```

**Zone 5 (variable BPM) special case:**
Zone 5 uses a pre-rendered audio file with built-in tempo automation. BeatManager cannot track a variable-BPM stream precisely. Instead, use a pre-baked timing map: an array of timestamps (in seconds from track start) at which each beat occurs. This array is authored once and stored in a resource file (`zone_5_beat_map.tres`). BeatManager reads the map and uses `music_player.get_playback_position()` to look up the current beat index.

---

### 4.2 Loop Point Implementation

All looping zone tracks must loop seamlessly. Godot 4 handles this with the `AudioStreamOGGVorbis` resource's loop settings.

**Setting loop points in code:**
```gdscript
func load_looping_track(path: String, loop_start: float, loop_end: float) -> AudioStreamOGGVorbis:
    var stream: AudioStreamOGGVorbis = load(path)
    stream.loop = true
    stream.loop_offset = loop_start   # in seconds; 0.0 = loop from beginning
    # loop_end is not directly settable via property in Godot 4.x —
    # instead, trim the OGG file itself at the loop_end point so the file
    # ends exactly at the loop point. The stream will then loop from
    # loop_offset back to the file start automatically.
    return stream
```

**Workflow for the developer:**
1. In Audacity (or any DAW), open the generated OGG file.
2. Find the loop point (the moment where the music naturally resolves back to bar 1).
3. Select from that point to the end of the file and delete.
4. Export as OGG Vorbis at quality level 6 (approximately 192 kbps).
5. Import into Godot. In the Import dock, check "Loop" and set Loop Offset to 0.
6. The file will now loop from its end back to its beginning seamlessly.

For tracks with a non-zero loop start (e.g., a 4-bar intro that should not repeat), set Loop Offset to the intro duration in seconds.

---

### 4.3 Latency Compensation — User-Adjustable Offset

**What is it (plain terms for the developer):**
Every phone's speaker and audio chip introduces a small delay between when the app sends a sound and when the player actually hears it. This delay is usually between 50ms and 300ms and varies between phone models. If the timing windows for rhythm hits are measured against the music clock but the player hears the music 150ms late, every tap will feel "wrong" even when the player is perfectly on time.

The offset setting lets the player correct for their specific phone. It shifts the entire game clock forward or backward in tiny steps. A positive offset means "I hear the music later than the game thinks — shift the windows to match." A negative offset is rare but can occur on some devices.

**How to expose it in Settings:**
- Show a simple slider labeled "Timing Adjust" with a range of −200ms to +200ms, default 0ms.
- Add a calibration screen: play a steady 4/4 click track and ask the player to tap along. Measure the average tap-to-beat difference and auto-set the offset.
- Store the offset in the user's save data (`user_offset_sec = offset_ms / 1000.0`) and apply it in `BeatManager.start_zone()` as shown in 4.1.

**Technical note:**
`AudioServer.get_output_latency()` returns the device's reported output latency. Subtract this from `AudioServer.get_time_since_last_mix()` in `_process` to get the corrected now-time (as shown in the pseudocode). The user offset is added on top of this automatic correction for phones whose reported latency is inaccurate.

---

### 4.4 App Background / Foreground Handling

When the player receives a call, switches apps, or the OS pauses the game, audio must stop cleanly and resume correctly.

```gdscript
# Add to your main Game.gd or an Autoload

func _notification(what: int) -> void:
    match what:
        NOTIFICATION_APPLICATION_PAUSED:
            # App is going to background
            AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
            BeatManager.music_player.stream_paused = true

        NOTIFICATION_APPLICATION_RESUMED:
            # App returning to foreground
            AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
            BeatManager.music_player.stream_paused = false
            # Resync the beat clock to the current playback position
            BeatManager.resync_to_playback_position()
```

Add `resync_to_playback_position()` to BeatManager:
```gdscript
func resync_to_playback_position() -> void:
    var pos: float = music_player.get_playback_position()
    var beats_elapsed: float = pos / beat_duration_sec
    beat_count = int(beats_elapsed)
    var fractional_beat: float = beats_elapsed - float(beat_count)
    next_beat_time = AudioServer.get_time_since_last_mix() + ((1.0 - fractional_beat) * beat_duration_sec)
```

**Important:** Do not call `music_player.play()` on resume — only unpause. Calling `play()` restarts the track from the beginning, losing the player's position mid-level.

---

### 4.5 Volume Bus Structure

Set up Godot's audio buses as follows in the AudioServer (Project > Audio menu):

```
Master Bus (default, cannot be renamed)
  └── Music Bus
  └── SFX Bus
  └── UI Bus
```

**Recommended default volumes (linear, set in code or Project Settings):**
| Bus | Default dB | Notes |
|---|---|---|
| Master | 0 dB | Controlled by OS volume; do not touch in-game |
| Music | −6 dB | Slightly ducked to leave headroom for SFX |
| SFX | −3 dB | Gameplay-critical; must be clearly audible |
| UI | −9 dB | Button taps and menu sounds; should be subtle |

**Setting up in code:**
```gdscript
func _ready() -> void:
    # Assign buses (do this once at game start)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), -6.0)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), -3.0)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI"), -9.0)
```

**Player-facing volume settings:**
Expose two sliders in Settings: "Music Volume" and "Sound Effects Volume." These control the Music and SFX buses respectively. The UI bus volume is always tied to the SFX slider (set UI volume = SFX volume − 6 dB).

**Music ducking during SFX:**
For the `level_complete` and `zone_unlock` SFX (which are long and musical), apply a temporary duck to the Music bus:
```gdscript
func duck_music(duration_sec: float) -> void:
    var tween: Tween = create_tween()
    tween.tween_method(
        func(v): AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), v),
        -6.0, -18.0, 0.1
    )
    await get_tree().create_timer(duration_sec).timeout
    var tween2: Tween = create_tween()
    tween2.tween_method(
        func(v): AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), v),
        -18.0, -6.0, 0.5
    )
```

---

## SECTION 5 — PLUG-IN GUIDE (For the Developer — No Audio Experience Needed)

This guide walks you through generating, converting, and adding every music track to the game. Follow these steps in order for each track. It takes about 10–15 minutes per track once you get the hang of it.

---

**What you need before you start:**
- A free Suno AI account at suno.com (or Udio at udio.com — either works)
- Audacity (free download at audacityteam.org) — this is the audio editor you'll use to trim and export files
- OR if you prefer the command line, FFmpeg (free at ffmpeg.org) — one-line command provided below
- The Bubble Reef Rush project open in Godot

---

**Step 1 — Open Suno AI and start a new song**

Go to suno.com and click "Create." Make sure you are in "Custom Mode" (there is a toggle — click it). This gives you two text boxes: one for lyrics and one for style. Leave the lyrics box blank or type the word `instrumental`. Paste the content from the SUNO PROMPT block for your track (everything inside the `[ ]` brackets) into the Style box. Click Generate. Suno will make two versions at once — listen to both.

---

**Step 2 — Pick the best version and extend it if needed**

Listen for: Does it match the mood description in Section 1? Is there any singing or talking? (If yes, reject it and generate again.) Does it have a clean beginning with no long silence or fade-in? Does it end without an obvious fade-out? The best track for looping starts strong and ends strong. If Suno generates a 30-second clip but you want more material to work with, click "Extend" to make it longer before downloading.

---

**Step 3 — Download the file**

Click the three-dot menu on the track and choose Download. Suno downloads as MP3. Save it somewhere easy to find, like your Desktop, with a name you'll recognize (e.g., `zone1_sunlit_take1.mp3`).

---

**Step 4 — Open the file in Audacity and find the loop point**

Open Audacity. Go to File > Import > Audio and select your downloaded MP3. The waveform will appear. Press the spacebar to play it. Listen for the natural "end" of the musical phrase — the moment where the music resolves and would naturally start over. This is your loop point. Click on the waveform at that moment to place the cursor there. Look at the bottom of the screen — Audacity shows the time position in seconds. Write that number down (e.g., 32.41 seconds). That is your loop_end_sec value for the JSON manifest.

---

**Step 5 — Trim the file to the loop point**

In Audacity, click exactly at your loop point (the time you found in Step 4). Then press Shift+End to select from your cursor to the end of the file. Press Delete to remove everything after the loop point. Now your file ends exactly at the loop point. Optionally, also trim the beginning: if the track starts with a moment of silence, click at the beginning of the silence, then Shift+click at the first audible note, and delete the silence.

---

**Step 6 — Export as OGG**

In Audacity, go to File > Export > Export as OGG Vorbis. In the Quality slider, set it to 6 (this gives about 192 kbps quality, which sounds great on phone speakers without using too much storage). Name the file exactly as specified in the manifest — for example: `zone_1_sunlit_shallows.ogg`. Save it directly into the correct folder in your project (see Step 7 for the folder path).

**FFmpeg alternative (command line — optional):**
If you prefer not to use Audacity, open a terminal and run this command (replace the filenames and trim time with your values):
```
ffmpeg -i zone1_sunlit_take1.mp3 -t 32.41 -c:a libvorbis -q:a 6 zone_1_sunlit_shallows.ogg
```
`-t 32.41` trims the file to 32.41 seconds. Change this to your loop point.

**Free online converter alternative:**
Go to cloudconvert.com, upload your MP3, choose OGG as the output format, and download. Note: online converters do not let you set a precise trim point, so you will need to trim in Audacity first and then convert, or use the FFmpeg command above.

---

**Step 7 — Drop the file into the right project folder**

Place the exported OGG file here inside your Godot project:

| File type | Folder path |
|---|---|
| Zone music loops | `assets/audio/music/` |
| Speed-up variants | `assets/audio/music/` |
| Jingles (win, fail) | `assets/audio/music/` |
| Menu theme | `assets/audio/music/` |
| Editor ambient | `assets/audio/music/` |
| Sound effects | `assets/audio/sfx/` |

If those folders do not exist yet, create them inside your Godot project's `assets/` folder.

---

**Step 8 — Import and configure the file in Godot**

Switch to Godot. In the FileSystem dock, navigate to the folder where you put the file. Godot will automatically detect and import it. Click on the file to select it. In the Import dock on the right side, check the box that says "Loop." Leave Loop Offset at 0 (the track loops from the beginning). Click "Reimport." That's it — the track will now loop seamlessly in-game.

---

**Step 9 — Hook it up to the correct AudioStreamPlayer**

In your Zone scene (or the ZoneManager script), find the AudioStreamPlayer node for that zone. In the Inspector, drag your new OGG file from the FileSystem dock into the Stream property. If you are using the ZoneManager script, update the dictionary that maps zone IDs to audio paths so it points to the new file.

---

**Step 10 — Test it in-game**

Press F5 to run the game (or the Play button). Navigate to the zone whose music you just added. Listen for: Does the music start immediately with no delay? Does it sound like the mood in Section 1? When the loop wraps around, is the transition seamless (no click, no gap, no jump in the melody)? If the loop has a small click, go back to Audacity and nudge the trim point by ±100ms and re-export. One or two tries usually fixes any loop click.

**Troubleshooting tip:** If the music sounds too quiet, increase the volume_db property on the AudioStreamPlayer node in Godot's Inspector (try +3 dB or +6 dB). If it sounds distorted, reduce it.

---

*End of Audio Bible — Bubble Reef Rush v1.0*
*Prepared by Audio Director C-4, 2026-06-06*
