# Bubble Reef Rush — Human Setup Guide

**Who this is for:** You, Terry. This guide covers every step that a human must complete
personally — things that require your accounts, your physical devices, your legal agreements,
or your creative judgment. AI agents handle the code; this guide handles everything else.

**How to use it:** Work through sections in order for a first-time setup. Return to individual
sections later when you need a refresher (e.g., "how do I build the release AAB again?").

**Platform assumption:** These instructions assume a Mac or Linux development machine.
Windows commands differ; ask Claude Code if you're on Windows and need a translation.

---

## Section 1: Development Environment Setup

### 1. Install Godot 4.3

1. Open a browser and go to: `https://godotengine.org/download/archive/4.3-stable/`
2. Download the correct build for your machine:
   - **Mac (Apple Silicon / M-series):** `Godot_v4.3-stable_macos.universal.zip`
   - **Mac (Intel):** `Godot_v4.3-stable_macos.universal.zip` (same file — it's a universal binary)
   - **Linux (64-bit):** `Godot_v4.3-stable_linux.x86_64.zip`
3. Also download the **export templates** from the same page:
   - File name: `Godot_v4.3-stable_export_templates.tpz`
   - This file is required to build Android APKs and AABs from Godot. It is about 1 GB.
4. Unzip the Godot application:
   - **Mac:** Move `Godot.app` to your `/Applications` folder.
   - **Linux:** Move the binary to `/usr/local/bin/godot` or anywhere on your `$PATH`.
5. Install the export templates inside Godot:
   - Launch Godot. You will see the Project Manager screen.
   - Go to **Editor > Manage Export Templates** (top menu bar).
   - Click **Install from File**.
   - Select the `.tpz` file you downloaded in step 3.
   - Wait for installation to complete (progress bar in the lower-right corner).
   - When finished, the "Status" column will show a green checkmark next to `4.3-stable`.

### 2. Install Android Studio and the Android SDK

Android Studio is Google's IDE for Android development. You only need it for its SDK
tools — you will not write Android code in it.

1. Go to: `https://developer.android.com/studio`
2. Click **Download Android Studio** and follow the installer for your OS.
3. Launch Android Studio. During first-run setup, accept all defaults (Standard setup).
   This will automatically install the Android SDK, Android Emulator, and build tools.
4. Once setup completes, open the **SDK Manager**:
   - **Mac:** Android Studio menu > **Settings** > **Languages & Frameworks** > **Android SDK**
   - **Linux:** **File** > **Settings** > **Languages & Frameworks** > **Android SDK**
5. In the **SDK Platforms** tab, check that **Android 14 (API Level 34)** is installed.
   If it shows "Not Installed", check the box and click **Apply**.
6. Switch to the **SDK Tools** tab. Verify these are installed (check boxes if not):
   - Android SDK Build-Tools (latest version, e.g. 34.0.0)
   - Android SDK Command-line Tools (latest)
   - Android Emulator
   - Android SDK Platform-Tools (this gives you `adb`)
7. Note the **Android SDK Location** path shown at the top of the SDK Manager window.
   You will need this path when configuring Godot. It looks like:
   - **Mac:** `/Users/yourname/Library/Android/sdk`
   - **Linux:** `/home/yourname/Android/Sdk`

### 3. Install the Java JDK

Godot 4 requires **Java 17** (JDK 17). Earlier or later major versions may cause
build errors.

**Mac (using Homebrew — recommended):**

```bash
brew install openjdk@17
```

After installation, Homebrew will print a command to add Java to your PATH. Run it.
It looks like:

```bash
sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk \
  /Library/Java/JavaVirtualMachines/openjdk-17.jdk
```

**Linux (Ubuntu/Debian):**

```bash
sudo apt update
sudo apt install openjdk-17-jdk
```

**Verify the installation:**

```bash
java -version
```

You should see output containing `openjdk 17`. If you see a different version number,
your system's default Java needs to be changed. On Linux: `sudo update-alternatives
--config java` and select Java 17.

### 4. Install Git

Check if Git is already installed:

```bash
git --version
```

If you see `git version 2.x.x` you're done. If not:

- **Mac:** `brew install git`
- **Linux (Ubuntu/Debian):** `sudo apt install git`

### 5. Open the Bubble Reef Rush Project in Godot

1. Launch Godot. The Project Manager opens.
2. Click **Import** (not "New").
3. Navigate to `/home/user/bubble-reef-rush/` and select the `project.godot` file.
4. Click **Open**.
5. Godot will import all assets. This takes 30–60 seconds on a first open. You will
   see a progress bar. Wait for it to finish.
6. The project will open in the Godot editor.

### 6. Connect Godot to the Android SDK

You need to tell Godot where you installed the Android SDK and Java.

1. In Godot, go to **Editor > Editor Settings** (top menu bar).
2. In the left panel, expand **Export** and click **Android**.
3. Set **Android SDK Path** to the path you noted in step 7 of the Android Studio
   installation (e.g., `/home/yourname/Android/Sdk`).
4. Set **Java SDK Path** to your Java 17 installation. Find it with:
   ```bash
   # Mac:
   /usr/libexec/java_home -v 17
   # Linux:
   dirname $(dirname $(readlink -f $(which java)))
   ```
   Paste that output into the Godot field.
5. Click **OK** to save Editor Settings.

### 7. Verify Everything Is Set Up

1. In Godot, go to **Project > Export** (top menu bar).
2. If an Android export preset already exists, click on it. If not, click **Add** and
   select **Android**.
3. At the bottom of the Export dialog, you should see green text saying "No issues
   found." If you see red or yellow warnings, they will describe exactly what is
   missing. Common fixes:
   - "JDK not found" — re-check your Java SDK path in Editor Settings.
   - "Android SDK not found" — re-check your Android SDK path.
   - "Export templates not installed" — re-do step 5 of the Godot installation above.
4. Close the Export dialog. You're ready to build.

---

## Section 2: Android Build Setup

### 1. Generate a Debug Keystore for Development Testing

A keystore is a cryptographic file that signs your app. Android requires all APKs to
be signed before installing them, even for testing. The debug keystore signs
development builds — it is not used for the Play Store.

Run this command in your terminal (all one line):

```bash
keytool -genkey -v -keystore ~/bubble-reef-rush-debug.keystore \
  -storepass android -alias androiddebugkey \
  -keypass android -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=Android Debug,O=Android,C=US"
```

This creates the file `~/bubble-reef-rush-debug.keystore`. No prompts — the `-dname`
flag fills in the certificate details automatically.

### 2. Generate a Release Keystore for Production

**This is the most important step in this entire guide. Read it carefully before running.**

> **WARNING: Back up your release keystore immediately after creating it, and store it
> in at least two separate safe locations (e.g., a password manager like 1Password or
> Bitwarden, plus an encrypted USB drive). If you lose this file, you cannot update
> your app on Google Play. Ever. You would have to unpublish the app and republish
> under a new package name, losing all your reviews and download history. There is no
> recovery process.**

Run this command:

```bash
keytool -genkey -v \
  -keystore ~/bubble-reef-rush-release.keystore \
  -alias bubblereef \
  -keyalg RSA -keysize 2048 -validity 10000
```

You will be prompted interactively to enter:

- **Keystore password** — Choose a strong password. Write it down somewhere safe.
  You will need it every time you build a release.
- **Key password** — Can be the same as the keystore password for simplicity.
- **First and Last Name** — Your full name or company name.
- **Organizational Unit** — You can type "indie" or "none".
- **Organization** — "Terry Maloney" or your business name.
- **City, State, Country** — Your real location.

When prompted "Is CN=... correct?", type `yes` and press Enter.

The file `~/bubble-reef-rush-release.keystore` is now created.

**Back it up right now before continuing.**

### 3. Configure the Keystore in Godot Export Settings

1. In Godot, go to **Project > Export**.
2. Select (or create) the **Android** export preset.
3. Click the **Options** tab within the export preset.
4. Scroll down to the **Keystore** section. You will see two sub-sections:
   **Debug** and **Release**.
5. For **Debug**:
   - Set **Debug Keystore** to the path: `~/bubble-reef-rush-debug.keystore`
   - Set **Debug Keystore User** to `androiddebugkey`
   - Set **Debug Keystore Password** to `android`
6. For **Release**:
   - Set **Release Keystore** to the path: `~/bubble-reef-rush-release.keystore`
   - Set **Release Keystore User** to `bubblereef`
   - Set **Release Keystore Password** to the password you chose in step 2.

> **Warning: The release keystore password is stored in your Godot project settings.
> Do not commit the `export_presets.cfg` file to a public Git repository. Add it to
> `.gitignore` if your repository is public.**

### 4. Set the Package Name

1. Still in **Project > Export > Android**, click the **Options** tab.
2. Find the **Package** section.
3. Set **Unique Name** to: `com.terrymaloney.bubblereef`
   - This identifier can never be changed after publishing. Choose carefully.
   - It must be unique across all apps on Google Play.
   - Convention: reverse your domain name + app name, all lowercase.
4. Set **App Name** to: `Bubble Reef Rush`
5. Set **Version Name** to: `1.0.0`
6. Set **Version Code** to: `1` (you increment this integer with every Play Store upload).

### 5. Build a Debug APK for Device Testing

1. Connect your Android device to your computer via USB.
2. On your Android device, enable **Developer Options**:
   - Go to **Settings > About Phone**.
   - Tap **Build Number** seven times. You will see "You are now a developer!"
   - Go back to **Settings > System > Developer Options**.
   - Enable **USB Debugging**.
3. In Godot, go to **Project > Export**.
4. Select the **Android** export preset.
5. Click **Export Project** (not "Export PCK/ZIP").
6. In the file dialog:
   - Navigate to a folder for build output (e.g., `/home/user/bubble-reef-rush/export/`)
   - Set the filename to `bubble_reef_rush_debug.apk`
   - Make sure **Export With Debug** is checked.
7. Click **Save**. Godot will compile and sign the APK. This takes 1–3 minutes.

### 6. Install the Debug APK on Your Android Device

With your device connected and USB debugging enabled:

```bash
adb install /home/user/bubble-reef-rush/export/bubble_reef_rush_debug.apk
```

If `adb` is not found, add the Android SDK platform-tools to your PATH:

```bash
# Add to your ~/.bashrc or ~/.zshrc:
export PATH="$PATH:$HOME/Android/Sdk/platform-tools"
# Then reload:
source ~/.bashrc
```

A successful install prints: `Performing Streamed Install` followed by `Success`.

The app will appear in your device's app drawer. Tap it to launch.

### 7. Build a Release AAB (Android App Bundle) for the Play Store

Google Play requires an AAB file (not an APK) for new app submissions.

1. In Godot, go to **Project > Export**.
2. Select the **Android** export preset.
3. In the **Options** tab, confirm **Release** keystore details are filled in (section 3 above).
4. Click **Export Project**.
5. In the file dialog:
   - Set the filename to `bubble_reef_rush_v1_0_0.aab`
   - Make sure **Export With Debug is NOT checked** (release build).
6. Click **Save**. This takes 2–5 minutes.
7. The `.aab` file is what you upload to Google Play Console.

> **Note:** An AAB cannot be installed directly on a device via `adb`. To test on a
> device, always use an APK. Use AAB only for Play Store uploads.

### 8. What to Check on the Physical Device Before Submitting

See the full checklist in Section 7. At minimum before your first submission:

- Launch the app cold (first time after install) — no crash.
- Play through the first 30 seconds of gameplay.
- Tap the back button — does the game handle it gracefully?
- Background the app mid-game and return to it — does it resume correctly?
- Check that the app icon and name appear correctly in the app drawer.

---

## Section 3: Music Generation (AI Tools)

The game needs original music for each zone. Prompts for every track are in
`docs/audio/audio_bible.md`. This section walks you through generating, downloading,
and preparing those tracks.

> **IMPORTANT — Commercial Licensing Warning: Free tiers of AI music tools (Suno and
> Udio) generally do NOT grant commercial rights. Before publishing Bubble Reef Rush
> on the Play Store, you must be on a paid subscription plan that explicitly grants
> commercial/monetization rights. Check each platform's current Terms of Service
> before relying on a track. Terms change frequently.**

### 1. Suno AI

- **Website:** `https://suno.com`
- **Free tier:** ~50 credits/day (roughly 10–15 songs). Does not include commercial rights.
- **Pro plan ($8/month as of 2025):** 2,500 credits/month, commercial rights included for
  songs you generate while subscribed.
- **Premier plan ($24/month):** 10,000 credits/month, commercial rights.

To sign in: use your Google account or create a Suno account with your email.

### 2. Udio

- **Website:** `https://www.udio.com`
- **Free tier:** Limited generations per month, no commercial rights.
- **Standard plan (~$10/month):** More generations, commercial rights.

To sign in: use your Google account or create a Udio account.

### 3. Generating Each Track

1. Open `docs/audio/audio_bible.md` in any text editor (or ask Claude Code to open it).
2. Find the section for the track you want to generate. Each entry has:
   - A track name (e.g., "Zone 1: Shallow Reef — Bubbly Morning")
   - A style prompt
   - Tags/keywords
   - Target BPM and mood
3. Copy the style prompt from the document.
4. In Suno or Udio, click **Create** (Suno) or the **+** / **Create** button (Udio).
5. Paste the prompt into the text field.
6. Enable **Custom Mode** (Suno) or equivalent — this lets you control the style more
   precisely and prevents the AI from auto-generating lyrics.
7. Set the mode to **Instrumental** (no vocals) unless the audio bible specifies lyrics.
8. Click **Generate** (Suno) or **Create** (Udio). Two versions are generated at once.
9. Listen to both. If neither fits the zone's mood, click **Regenerate** (Suno) or
   **Create** again (Udio). You can generate as many times as your credits allow.
10. Pick the take that:
    - Starts cleanly with no long silence at the beginning
    - Has a beat that matches the target BPM in the audio bible
    - Feels right for the age group (bright, not aggressive)

### 4. Downloading from Suno and Udio

**Suno:**
1. Hover over the generated track.
2. Click the **three-dot menu (...)** that appears.
3. Select **Download > Audio (.mp3)**.
4. Save to a staging folder like `~/Downloads/brr_music_staging/`.

**Udio:**
1. Click on the generated track to open its detail view.
2. Click the **Download** button (downward arrow icon, top-right of the track card).
3. Select **MP3**.
4. Save to the same staging folder.

### 5. Convert MP3 to OGG Using FFmpeg

Godot works best with OGG Vorbis audio. FFmpeg is a free command-line audio converter.

**Install FFmpeg:**

- **Mac:** `brew install ffmpeg`
- **Linux:** `sudo apt install ffmpeg`

**Convert a single file:**

```bash
ffmpeg -i input.mp3 -c:a libvorbis -q:a 5 output.ogg
```

- `-q:a 5` sets quality level 5 (range 0–10). Level 5 is a good balance of quality and
  file size for game music. Use 7–8 for higher fidelity if file size isn't a concern.

**Batch convert all MP3s in a folder:**

```bash
for f in ~/Downloads/brr_music_staging/*.mp3; do
  ffmpeg -i "$f" -c:a libvorbis -q:a 5 "${f%.mp3}.ogg"
done
```

### 6. Alternative: Convert Using Audacity (GUI)

Audacity is a free, open-source audio editor — useful if you prefer a visual interface.

1. Download from: `https://www.audacityteam.org/download/`
2. Open Audacity.
3. Go to **File > Import > Audio** and open your MP3.
4. Go to **File > Export > Export as OGG Vorbis**.
5. Set **Quality** to 5 (matches the FFmpeg command above).
6. Save the file with your target filename.

### 7. Trim Silence from the Beginning

This is important. If the audio has even 100ms of silence at the start, the beat will
feel off as soon as the level begins. Use Audacity:

1. Open the OGG file in Audacity.
2. Press **Play** and watch the waveform. The audio should start right at the beginning
   of the waveform — the first visible peak.
3. If there is a flat (silent) section at the start:
   - Click at the very beginning of the track (time 0:00.000).
   - Shift-click where the first audible sound begins.
   - Press **Delete** on your keyboard.
4. Go to **Edit > Clip Boundaries > Join** if needed to clean up.
5. Re-export the file (File > Export > Export as OGG Vorbis, overwrite the old file).

### 8. Set a Loop Point in Audacity

For tracks that need to loop seamlessly (zone background music):

1. Open the OGG file in Audacity.
2. Listen for the natural loop point — usually where the track could repeat without
   an audible "seam." For a 4-bar loop, this is typically at the end of bar 4.
3. Click at the loop start point in the waveform.
4. Go to **Edit > Labels > Add Label at Selection** and type `LOOP_START`.
5. Click at the loop end point (where playback should jump back to LOOP_START).
6. Add a label: `LOOP_END`.
7. Export as OGG Vorbis.

In Godot, AudioStreamOGGVorbis has a `loop` property and `loop_offset` that you set
in the AudioStreamPlayer node. The exact offset values (in seconds) come from the loop
points you identified in Audacity. Note them down and give them to the developer (or
enter them in Godot directly).

### 9. Where to Put the Finished OGG Files

Place completed OGG files at:

```
assets/audio/music/zone_1_shallow_reef.ogg
assets/audio/music/zone_2_name.ogg
assets/audio/music/zone_3_name.ogg
...
```

The exact naming convention for each track is in `docs/audio/audio_bible.md`.

If the `assets/audio/music/` directory doesn't exist yet:

```bash
mkdir -p /home/user/bubble-reef-rush/assets/audio/music/
```

### 10. Test the Music in-Game

1. Open Godot with the Bubble Reef Rush project.
2. In the FileSystem panel (bottom-left), navigate to `assets/audio/music/`.
3. Drag your OGG file onto an `AudioStreamPlayer` node in the scene you want to test.
   The main gameplay scene is likely at `src/scenes/gameplay.tscn` or similar.
4. Click the **Play** button at the top of the editor to run the scene.
5. You should hear the music start immediately when the scene loads.
6. Check: does it sound right? Is there a beat drop at the right moment?

---

## Section 4: Art Asset Creation

The game needs character sprites, background tiles, UI elements, and effect animations.
The full specification is in `docs/art/art_bible.md`. You have two paths to create
these assets.

---

### Path A: AI Art Tools (Faster, Solo)

#### 1. Midjourney

Midjourney is an AI image generator accessed through Discord.

- **Website:** `https://www.midjourney.com`
- To use it: sign up at midjourney.com, then join their Discord server when prompted.
- Type prompts in the `#general` channels or use the Midjourney bot in your own server.
- **Free tier:** Was removed in 2024 — a subscription is required. Basic plan starts
  at approximately $10/month and includes commercial usage rights.

#### 2. Reading the Art Bible for Specs

Before generating any image, read `docs/art/art_bible.md`. For each asset, note:

- **Pixel dimensions** (e.g., 64x64px, 128x128px)
- **Color palette** (the game uses a specific palette for visual consistency)
- **Style keywords** (e.g., "soft edges, pastel, cute, underwater")
- **View angle** (side view for characters, front view for UI elements)
- **Number of animation frames** (if it's a sprite sheet)

#### 3. Writing a Midjourney Prompt for a Game Sprite

Example prompt for Pebble the pufferfish (the main character):

```
/imagine cute pufferfish cartoon character, side view, underwater scene, soft pastel
blue and yellow colors, big friendly eyes, slightly inflated, simple clean design
suitable for kids mobile game, transparent background, flat 2D vector style, 
sprite sheet 4 frames idle animation --ar 1:1 --no background --style cute
```

Key techniques:
- Always include **side view** for character sprites (the game is a side-scrolling runner).
- Always include **--no background** to get a transparent or white background.
- Specify the **color palette** from the art bible.
- Add **kids mobile game** to keep the style age-appropriate.
- Use `--ar 1:1` for square sprites (most game characters).

If you don't like a result, click the **V1/V2/V3/V4** buttons below the generated image
to create variations of that specific version, or click the refresh icon to generate
four completely new versions from the same prompt.

#### 4. Getting a Transparent Background

Midjourney does not reliably produce true PNG transparency. Use one of these methods:

**Option A — remove.bg (easiest):**
1. Go to `https://www.remove.bg`
2. Upload your downloaded image.
3. Download the result with the background removed (free for web-resolution images;
   paid for full resolution).

**Option B — Photopea manual selection:**
1. Go to `https://www.photopea.com` (free, browser-based Photoshop alternative).
2. Open your image (File > Open).
3. Use the **Magic Wand tool** (W key) to click on the background.
4. If the selection is good, press **Delete**.
5. Go to **File > Export As > PNG** to save with transparency.

#### 5. Resize and Export at Correct Pixel Dimensions

Game sprites need to be exact pixel sizes. Use Photopea:

1. Open the image in Photopea (`https://www.photopea.com`).
2. Go to **Image > Image Size**.
3. Set the width and height to the values from the art bible (e.g., 64x64).
4. Set **Resample** to **Nearest Neighbor** for pixel art (hard edges) or
   **Bicubic Sharper** for smooth art (like Pebble).
5. Click **OK**.
6. Go to **File > Export As > PNG**.
7. Make sure **Save Transparency** is checked.
8. Click **Save**.

#### 6. Where to Put Art Files

```
assets/art/characters/pebble_idle.png
assets/art/characters/pebble_dive.png
assets/art/characters/pebble_float.png
assets/art/backgrounds/zone_1_shallow_reef_bg.png
assets/art/ui/button_play.png
assets/art/ui/button_dive.png
assets/art/obstacles/jellyfish.png
assets/art/obstacles/sea_urchin.png
assets/art/collectibles/bubble_note.png
```

The complete list of required files and their exact sizes is in `docs/art/art_bible.md`.

---

### Path B: Hiring an Artist (Higher Quality)

This approach takes longer and costs more but produces more polished, consistent art.

#### 1. Where to Find Game Artists

- **itch.io:** `https://itch.io/game-assets` — many indie artists sell asset packs and
  take commissions here. Filter by style (2D, pixel art, vector).
- **ArtStation:** `https://www.artstation.com` — search "2D game artist for hire" or
  "mobile game art." Higher-end professionals are here.
- **Upwork:** `https://www.upwork.com` — good for finding artists with verifiable
  reviews. Post a job or search for freelancers.
- **Twitter/X:** Search `#gamedev #pixelart #commissions` or `#2dartist commissions open`.
  Many indie game artists take commissions directly.
- **Fiverr:** `https://www.fiverr.com` — lower cost, variable quality. Good for one-off
  assets like icons.

#### 2. What to Share with the Artist

Before contacting anyone, prepare a brief. Share:

- The art bible: `docs/art/art_bible.md`
- The world bible (for tone and setting): `docs/narrative/world_bible.md`
- A short description: "Bubble Reef Rush is a rhythm game for kids ages 4–10. The main
  character is Pebble, a cute pufferfish. The game world is a colorful shallow reef,
  pastel colors, not scary, very friendly and approachable."
- The complete list of assets you need (from the art bible) and your timeline.
- Examples of art styles you like (reference images help enormously).

#### 3. What File Formats to Request

Tell the artist explicitly:

- **Format:** PNG with transparency (not JPG, not WebP)
- **Sprite sheets:** Ask for individual frames exported separately AND as a horizontal
  sprite sheet (all frames in one PNG, left to right)
- **Source files:** Request the original project file (Aseprite, Photoshop PSD, or
  Illustrator AI) in addition to PNGs — so you can make edits later without rehiring
- **Resolution:** 2x or 3x the final game pixel size (so a 64x64 game sprite should be
  delivered at 128x128 or 192x192, and you scale it down in the game engine)

#### 4. Rough Price Ranges (2025 Reference)

These vary significantly by artist experience and location. Use as a planning guide only.

| Asset Type               | Approximate Range |
|--------------------------|-------------------|
| Simple character (4 frames) | $50–$200       |
| Background tile set (10 tiles) | $80–$300    |
| UI element set (10 buttons/icons) | $50–$150 |
| Full character sprite sheet (8+ frames) | $150–$500 |
| Full game art package (all assets) | $500–$3,000 |

Budget for revisions (typically 1–2 revision rounds are included in a commission; more
may cost extra). Always agree on revision count, timeline, and payment terms in writing
before work begins.

---

## Section 5: Google Play Submission

You already have a Google Play developer account. This section walks through creating
the app listing, configuring it for the Families program, and submitting your first build.

### 1. Open Google Play Console

Go to: `https://play.google.com/console`

Sign in with the Google account linked to your developer account.

### 2. Create a New App

1. On the Play Console home page, click **Create app** (top-right button).
2. Fill in the form:
   - **App name:** `Bubble Reef Rush`
   - **Default language:** English (United States)
   - **App or game:** Select **Game**
   - **Free or paid:** Select **Free** (you will add IAPs separately; the app itself
     is free to download)
3. Check both declaration checkboxes (developer program policies, export laws).
4. Click **Create app**.

You are now on the app's dashboard. The left sidebar shows all the setup tasks you
need to complete before you can publish.

### 3. Set Up the Google Play Families Program

The Families program is Google's certification for apps targeting children. It is
required for Bubble Reef Rush to appear in the Family section of the Play Store and to
be compliant with COPPA (US children's privacy law) and similar regulations.

1. In the left sidebar, go to **Policy > App content**.
2. Scroll to **Target audience and content** and click **Manage**.
3. Under **Target age groups**, select **Ages 5 and under** or **Ages 6–8** depending
   on your target. For Bubble Reef Rush (ages 4–10), selecting **Ages 6–8** covers
   the core audience without the most restrictive under-5 requirements. You may also
   select multiple age groups.
4. You will be asked: "Does your app target children as the primary audience?" Select
   **Yes, my app targets children as the primary audience.**
5. This will enroll you in the Play Families program and show additional compliance
   requirements.
6. Back in **App content**, you will now see a **Families self-certification** section.
   Complete it: confirm your app complies with the Families Policy (no behavioral ads,
   no data collection without parental consent, age-appropriate content).

> **Note:** Selecting "children as primary audience" enables stricter ad policies.
> Since Bubble Reef Rush uses only IAPs (no ads), this is not a problem.

### 4. Content Rating Questionnaire

1. In the left sidebar, go to **Policy > App content**.
2. Click **Start questionnaire** under **Content rating**.
3. Select **Games** as the category.
4. Answer the questions as follows for Bubble Reef Rush:
   - Violence: **No** (no realistic violence)
   - Sexual content: **No**
   - Profanity: **No**
   - Controlled substances: **No**
   - User-generated content (UGC): **No**
   - User interaction (chat, multiplayer): **No**
   - Social features: **No**
   - Location sharing: **No**
   - Personal information collected: **No** (if you add analytics later, revisit this)
5. Click **Save** and then **Calculate rating**.
6. Your rating will likely be **ESRB Everyone / PEGI 3** — appropriate for kids.
7. Click **Apply rating**.

### 5. Store Listing

1. In the left sidebar, go to **Store presence > Main store listing**.
2. Fill in each field using the copy from `docs/store/google_play_listing.md`:
   - **App name** (30 characters max)
   - **Short description** (80 characters max) — the one-liner
   - **Full description** (4,000 characters max)
3. Under **Graphics**, upload:
   - **App icon:** 512 x 512 PNG, no alpha
   - **Feature graphic:** 1024 x 500 PNG or JPG (this banner appears at the top of
     your listing)
   - **Screenshots:** Minimum 2, recommended 4–8. For phone: 1080 x 1920 or
     1080 x 2340 PNG. Take these from your physical device (press volume-down +
     power button simultaneously on most Android phones).
4. Under **Categorization**:
   - **App category:** Games > Music
   - **Tags:** Add relevant tags like "rhythm game", "kids", "music game"
5. Click **Save**.

### 6. Upload the AAB to the Play Store

Start with the Internal testing track — you can test with a small group before
submitting to production.

1. In the left sidebar, go to **Testing > Internal testing**.
2. Click **Create new release**.
3. Under **App bundles**, click **Upload** and select your
   `bubble_reef_rush_v1_0_0.aab` file.
4. Wait for the upload and processing to complete (1–5 minutes depending on file size).
5. Under **Release name**, enter `1.0.0 Internal Test`.
6. Under **Release notes**, type brief notes (e.g., "Initial internal test build").
7. Click **Save**, then **Review release**, then **Start rollout to Internal testing**.

**When ready for production:**

1. Go to **Production > Releases** in the left sidebar.
2. Click **Create new release**.
3. You can promote your AAB from the internal testing release (click **Add from
   previous releases**) or upload the same AAB file again.
4. Complete the release notes (these become your "What's New" text on the Play Store).
5. Click **Start rollout to Production**.

> **Note:** Your first submission goes through a human review by Google. This is not
> automated. See step 10 for review timelines.

### 7. Set Up In-App Products

1. In the left sidebar, go to **Monetize > In-app products**.
2. Click **Create product**.
3. For the full unlock product:
   - **Product ID:** `unlock_full_reef` (this ID is permanent — cannot be changed)
   - **Name:** `Full Reef Unlock`
   - **Description:** `Unlock all zones and levels in Bubble Reef Rush`
   - **Default price:** `$2.99`
   - Click **Save**.
4. Repeat for the Creator Pass:
   - **Product ID:** `creator_pass`
   - **Name:** `Creator Pass`
   - **Description:** `Behind-the-scenes art, music, and developer commentary`
   - **Default price:** `$1.99`
   - Click **Save**.
5. Set the status of both products to **Active** by clicking the toggle.

> **Note:** In-app product prices can be changed at any time after publishing. The
> product IDs are permanent.

### 8. Add Test Accounts for Internal Testing

1. Go to **Testing > Internal testing**.
2. Click the **Testers** tab.
3. Click **Create email list**, name it "Internal Testers", and add email addresses
   for the Google accounts of your testers (including your own non-developer account
   for testing purchases).
4. Click **Save changes**.
5. Share the opt-in URL (shown on the same page) with your testers. They must visit
   the URL and opt in before the app appears in their Play Store.

**To test IAPs without real charges:**
1. Go to **Setup > License testing** in the Play Console (left sidebar, under Setup).
2. Add the Google accounts of your testers to the **License testers** list.
3. License testers can make test purchases that go through the full purchase flow
   but are not charged real money.

### 9. Review Checklist Before Submitting for Review

Before clicking "Start rollout to Production" for the first time, verify:

- [ ] Content rating questionnaire is complete and rating is applied.
- [ ] Target audience settings are saved (Families program, ages selected).
- [ ] Privacy policy is uploaded. Go to **Policy > App content > Privacy policy**
      and enter a URL. You must host a privacy policy — use a free service like
      `https://www.privacypolicygenerator.info` to generate one and host it on
      GitHub Pages or similar.
- [ ] At least 2 screenshots are uploaded for phone form factor.
- [ ] App icon (512x512) and feature graphic (1024x500) are uploaded.
- [ ] Short description and full description are filled in.
- [ ] AAB is uploaded to the Production track.
- [ ] Both IAP products have status set to **Active**.
- [ ] The game has been tested on a real device end-to-end (see Section 7 checklist).
- [ ] The app name and description do not contain trademarked terms (e.g., "Pokémon",
      brand names, etc.).

### 10. Typical Review Timeline and What to Do If Rejected

**Timeline:** Google Play reviews typically take **1–3 business days** for a first
submission, and **1–2 hours to 1 business day** for subsequent updates. Apps targeting
children may receive additional scrutiny and can take up to 7 days.

**If rejected:**
1. You will receive an email from Google Play with a reason and a policy violation code.
2. Read the rejection reason carefully. Common reasons:
   - **Policy violation:** The rejection email will link to the specific policy. Read it.
   - **Metadata issues:** Your description or screenshots don't match the actual app.
   - **Families policy:** A required declaration is missing or incorrect.
   - **IAP issues:** Your IAP descriptions are unclear about what's being purchased.
3. Fix the issue, upload a new AAB (increment the Version Code in Godot's export
   settings), and resubmit.
4. If you disagree with the rejection or think it's a mistake, use the **Appeal** option
   in Play Console. Google usually responds to appeals within 1–3 business days.

---

## Section 6: iOS Setup (Future)

You don't need to do any of this now. This section is a preview so you know what's
coming when you're ready to ship on iOS.

### 1. Apple Developer Program Enrollment

- **URL:** `https://developer.apple.com/programs/`
- **Cost:** $99 USD per year, paid annually.
- **Who can enroll:** Individuals (your own name) or organizations (a registered
  business). For indie dev, individual enrollment is fine.
- **Time:** Enrollment takes 24–48 hours for identity verification. If you enroll as
  an organization, it can take 1–2 weeks.
- You will need a credit card and a valid Apple ID.

### 2. What You Need a Mac For

Unlike Android, iOS development **requires a Mac**. Specifically, you need:

- **Xcode** (Apple's IDE, free from the Mac App Store) — required to sign and submit
  the app to the App Store.
- **macOS:** Xcode only runs on macOS. If your primary machine is Linux, you have
  options: buy a used Mac Mini, rent a Mac in the cloud (MacStadium, MacInCloud), or
  ask a friend with a Mac to do the signing step.

### 3. Rough Additional Steps vs Android

1. In Godot, add an **iOS** export preset (same Export dialog as Android).
2. Export the Godot project as an Xcode project (`.xcodeproj` folder, not a binary).
3. Open the exported Xcode project in Xcode on a Mac.
4. In Xcode, configure signing with your Apple Developer account (select your team,
   let Xcode manage provisioning profiles automatically).
5. Build the app in Xcode for release (Product > Archive).
6. Use Xcode's Organizer (Window > Organizer) to submit to App Store Connect.
7. In App Store Connect (`https://appstoreconnect.apple.com`), create the app listing,
   fill in metadata, set pricing, and submit for review.
8. Apple's review process takes **1–2 business days** on average (faster for updates
   than initial submissions).

**iOS-specific considerations for Bubble Reef Rush:**

- Apple has a **parental gate requirement** for apps in the Kids category. Any link
  that exits the app (privacy policy, App Store links) must be behind a parental gate
  (a simple math question that a child can't answer, but a parent can).
- App Store pricing: $2.99 and $1.99 are both valid App Store price tiers.
- You will need to create new app screenshots at iOS-specific resolutions (6.7-inch
  and 6.1-inch iPhone displays are required).

---

## Section 7: Physical Device Testing Checklist

Test on a real Android device before every Play Store submission. The emulator does not
replicate real-world performance, touch latency, or audio timing accurately.

For each item below, note "PASS" or "FAIL" and the device model and Android version
you tested on.

**Audio**
- [ ] Music plays immediately when a level starts (no delay or silence at the start).
- [ ] Music loops seamlessly (no audible click or gap at the loop point).
- [ ] Sound effects play in sync with the beat (a tap on the beat feels satisfying,
      not "late").
- [ ] Audio works with the device volume at 50%, 100%, and with silent mode on
      (silent mode should mute the game, not crash it).
- [ ] Audio offset calibration setting moves the beat window and actually makes the
      game feel tighter or looser as expected.

**Controls**
- [ ] Hold to dive: character dives while finger is held, floats when released.
- [ ] Touch response feels snappy — no more than ~50ms perceptible delay.
- [ ] Multi-touch does not cause issues (some players rest a second finger on the
      screen while playing).

**Performance**
- [ ] Game runs at 60 fps throughout a full level. To verify: enable Godot's debug
      overlay by running the Debug APK and opening the Godot debug menu, or look for
      a debug fps display in the game's settings screen.
- [ ] No frame drops or stutters when multiple obstacles are on screen simultaneously.
- [ ] Level load time from tap to playable is under 3 seconds.

**Stability**
- [ ] No crash on level start.
- [ ] No crash on level complete (normal win).
- [ ] No crash on level fail (character hits obstacle).
- [ ] App backgrounded mid-level (home button) and returned to — game resumes or
      gracefully pauses.
- [ ] App killed via recent apps and relaunched — returns to main menu cleanly,
      no corrupted state.
- [ ] Device rotated mid-game — game handles it (locks to portrait or handles
      rotation without crash).

**Monetization**
- [ ] Tap the "Unlock Full Reef" button — IAP purchase dialog appears.
- [ ] Cancel the purchase — returned to the game with no change in state.
- [ ] Complete a test purchase (with a license tester account — no real charge) —
      game correctly unlocks the full content.
- [ ] Parental gate appears before any IAP dialog is shown.
- [ ] After purchase, IAP button changes state (e.g., no longer shows the buy button
      for content that's been purchased).

**UI and Accessibility**
- [ ] All text is legible on the device screen. Minimum readable text size is 12sp
      on a 5-inch screen.
- [ ] Buttons have adequate tap target sizes (minimum 48dp x 48dp per Google guidelines).
- [ ] The UI looks correct on a device with a notch or punch-hole camera (common on
      modern phones).
- [ ] The UI looks correct on a tablet (if you have one available to test on).

**Offline / Connectivity**
- [ ] Enable airplane mode and launch the app — it should work fully for core gameplay.
- [ ] If the IAP attempt fails in airplane mode, the error is handled gracefully (not
      a crash, shows a friendly message).

---

## Section 8: Ongoing Maintenance Checklist

Shipping is not the end — it's the beginning. This section covers what to do after launch.

### Pushing an Update

1. Make your code or content changes in Godot.
2. In Godot's export settings (**Project > Export > Android > Options**), increment the
   **Version Code** by 1 (e.g., 1 → 2). Also update the **Version Name** string
   (e.g., "1.0.0" → "1.0.1").
3. Build a new release AAB (see Section 2, step 7).
4. Go to **Google Play Console > Production > Releases > Create new release**.
5. Upload the new AAB.
6. Fill in the **Release notes** — this is the "What's New" text users see in the
   Play Store. Be specific: "Fixed audio timing on Zone 2. Added bonus level."
7. Submit for review. Updates typically go live within a few hours.

### Monitoring Crash Reports

1. In Play Console, go to **Android Vitals > Crashes & ANRs** (left sidebar).
2. You will see a list of crash types ranked by frequency and impact.
3. Click any crash to see the stack trace — the exact line of code that caused the crash.
4. Copy the stack trace and paste it to Claude Code with: "Here is a crash from
   production, please find the cause and fix it."
5. Google Play also tracks **ANRs** (Application Not Responding — when the app freezes
   for more than 5 seconds). These are shown in the same section.
6. Check this dashboard at least once a week after launch.

### Responding to User Reviews

1. In Play Console, go to **Store presence > Ratings and reviews**.
2. Read all new reviews. Reply to:
   - Bug reports: "Thank you for reporting this! We are investigating and will fix it
     in our next update."
   - Feature requests: "Great idea! We'll consider this for a future update."
   - 1-star reviews from crashes: "We're sorry to hear this! Please email
     [your support email] so we can help."
3. **Do not reply defensively to negative reviews.** Other potential customers read
   your responses. Be friendly and professional, especially since your audience
   includes parents of young children.
4. Replying to reviews does not change the star rating, but it shows other users that
   you are an active developer who cares about the product.

### When to Update the Privacy Policy

Update (or at minimum review) your privacy policy when you:

- Add any analytics SDK (Firebase, GameAnalytics, etc.)
- Add any advertising SDK
- Start collecting any new type of user data (email, device ID, usage stats)
- Add social features (leaderboards, accounts, multiplayer)
- Integrate with any third-party service that has its own data collection

**How to update it:**
1. Revise the privacy policy document (re-generate it at privacypolicygenerator.info
   or similar with the updated data collection details).
2. Re-host it at the same URL, or update the URL in Play Console.
3. In Play Console, go to **Policy > App content > Privacy policy** and confirm the URL
   is current and the page is publicly accessible.
4. If you significantly change what data is collected, consider adding an in-app
   notification for existing users.

---

*Last updated: 2026-06-06*
*Guide version: 1.0*
*For questions, open a Claude Code session and ask — or email your own developer notes
to yourself for later reference.*
