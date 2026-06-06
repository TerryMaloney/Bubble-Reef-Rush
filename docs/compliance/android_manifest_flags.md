# AndroidManifest.xml Flags — Bubble Reef Rush
**Google Play Families App: Required and Recommended Manifest Configuration**
**QA-2 Compliance Officer Reference**
**Version:** 1.0
**Date:** 2026-06-06
**Engine:** Godot 4.3
**Target:** Android (Google Play Families program, Mixed Audience ages 6-12)

> **Note:** This document describes manifest configuration requirements and recommendations. It is not legal advice. Verify against current Google Play Families Policy and Android documentation at time of build. Always test on physical devices after manifest changes.

---

## Overview: How Godot 4.3 Generates the Manifest

Godot 4.3 generates `AndroidManifest.xml` automatically from the project export settings. You do not edit the manifest directly in most cases. Instead, you:

1. Set export options in the Godot Export dialog (Project → Export → Android)
2. Use a **custom Android build** (Godot's "Use Custom Build" option) to get a full Android Studio project where you can modify `res/AndroidManifest.xml` directly
3. Add a **custom manifest additions file** (Godot supports `custom_build/AndroidManifest.xml` override snippets) via the export preset

For a Google Play Families app with specific compliance requirements, a **custom Android build** is strongly recommended. This gives full control over all manifest entries and avoids surprises from Godot's auto-generation.

---

## Section 1: Required Permissions

### 1.1 Permissions to INCLUDE

These permissions are needed for the game to function:

```xml
<!-- Required for IAP (Google Play Billing) -->
<uses-permission android:name="com.android.vending.BILLING" />

<!-- Required for internet connectivity (cloud save sync, IAP verification) -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Required to detect network state (show offline badge in-game per ui_copy.md) -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Optional but recommended: vibration for haptic feedback -->
<uses-permission android:name="android.permission.VIBRATE" />
```

**Godot auto-includes:** `INTERNET` and `ACCESS_NETWORK_STATE` are added automatically by Godot when internet is enabled in export settings. `VIBRATE` is added when vibration is enabled. `BILLING` is added by the Godot Google Play Billing plugin.

---

### 1.2 Permissions to OMIT — Critical for Kids App

**These permissions must NOT appear in the manifest for a Google Play Families app.**

| Permission | Why It Must Be Absent |
|------------|----------------------|
| `android.permission.ACCESS_FINE_LOCATION` | Precise GPS location. COPPA prohibits collecting precise location from children without verifiable parental consent. Not needed by this game. Google Play Families will flag this. |
| `android.permission.ACCESS_COARSE_LOCATION` | Approximate location. Same reasoning. Not needed. |
| `android.permission.ACCESS_BACKGROUND_LOCATION` | Background location. Same reasoning, and a higher-risk permission. |
| `com.google.android.gms.permission.AD_ID` | Advertising ID (GAID). Google requires apps targeting children under 13 to NOT declare this permission. Declaring it and being in the Families program is a policy violation. The game has no ads and must never read the advertising ID. |
| `android.permission.READ_CONTACTS` | Contacts access. Not needed. Would be alarming to parents. |
| `android.permission.READ_EXTERNAL_STORAGE` | External storage read. Not needed for Godot games — game data is in internal app storage. |
| `android.permission.WRITE_EXTERNAL_STORAGE` | External storage write. Same — not needed. |
| `android.permission.RECORD_AUDIO` | Microphone access. Game has no voice features. Not needed. |
| `android.permission.CAMERA` | Camera. Game has no camera features. Not needed. |
| `android.permission.READ_PHONE_STATE` | Phone state (IMEI etc.). Not needed. Gives access to persistent device identifiers — a concern under COPPA. |
| `android.permission.GET_ACCOUNTS` | Reads Google accounts on device. Not needed — GPGS handles auth internally. |

**Godot warning:** Godot 4.x may add some permissions based on which modules are compiled. When using a custom build, inspect the final compiled manifest with:

```bash
# After building the APK, decode the manifest to verify:
aapt dump xmltree app-release.apk AndroidManifest.xml | grep -i permission
# or use apkanalyzer:
apkanalyzer manifest permissions app-release.apk
```

Remove any unexpected permissions by editing `android/app/src/main/AndroidManifest.xml` in the custom build directory and removing the offending `<uses-permission>` lines.

---

## Section 2: Application-Level Flags

These flags go inside the `<application>` element of the manifest.

### 2.1 `android:usesCleartextTraffic`

```xml
<application
    android:usesCleartextTraffic="false"
    ...>
```

**Setting: `false` (required)**

Google Play Families and Google Play's general security requirements prohibit unencrypted HTTP traffic in apps targeting Android 9+. All network communication (GPGS cloud save, IAP verification) must use HTTPS. Setting `usesCleartextTraffic="false"` enforces this at the OS level and will cause the app to throw an error if any SDK attempts an unencrypted connection.

**Godot default:** Godot 4.3 does not set `usesCleartextTraffic` to false by default in all configurations. Verify and set explicitly in your custom build manifest.

**Exception process:** If any debug tool or test environment requires HTTP, use a `network_security_config.xml` that permits cleartext only for debug builds, not release builds.

---

### 2.2 `android:allowBackup`

```xml
<application
    android:allowBackup="true"
    android:fullBackupContent="@xml/backup_rules"
    ...>
```

**Setting: `true` with backup rules (recommended)**

`allowBackup="true"` allows Android to back up app data via Auto Backup. For a kids game, this is beneficial — if a child loses their device or resets it, their save data (which is also on GPGS cloud save) can be partially restored via Android backup.

However, you should define `backup_rules.xml` to **exclude sensitive data** (such as any cached purchase tokens) from the backup, while including the save game file.

**`res/xml/backup_rules.xml`:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
    <!-- Include the game save file -->
    <include domain="appdata" path="save_data.json" />
    <!-- Exclude any cached purchase receipts or session tokens -->
    <exclude domain="appdata" path="cache/" />
    <exclude domain="sharedpref" path="purchase_cache.xml" />
</full-backup-content>
```

**Alternative:** Set `android:allowBackup="false"` if GPGS cloud save is sufficient and you do not want Android to manage backup separately. This simplifies the data surface but means players lose local data if they reset their device without GPGS sync.

---

### 2.3 `android:networkSecurityConfig`

```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
```

**`res/xml/network_security_config.xml`:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    <!-- Debug only: allow cleartext for local testing -->
    <!-- Remove this block before release build -->
    <!--
    <debug-overrides>
        <trust-anchors>
            <certificates src="user" />
        </trust-anchors>
    </debug-overrides>
    -->
</network-security-config>
```

This enforces HTTPS-only traffic and ensures the app trusts only system CAs. Recommended for all apps; required for Google Play Families.

---

### 2.4 `android:exported` on Activities

Godot 4.3 creates a main activity. Ensure it is correctly configured:

```xml
<activity
    android:name="com.godot.game.GodotApp"
    android:exported="true"
    android:launchMode="singleInstancePerTask"
    android:configChanges="orientation|keyboardHidden|screenSize|smallestScreenSize|density|keyboard|navigation|screenLayout|uiMode"
    android:resizeableActivity="false"
    android:screenOrientation="portrait">

    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>
</activity>
```

**Key points:**
- `android:exported="true"` is required on the launcher activity (Android 12+)
- `android:screenOrientation="portrait"` — recommended for this game (designed for 1080×1920 portrait)
- `android:resizeableActivity="false"` — disables multi-window for a focused game experience

---

## Section 3: Required Meta-Data Tags for Play Families Compliance

### 3.1 Child-Directed Treatment Flag for Google Play Services

This flag tells Google Play Services (including any Google SDK used by the app) to apply child-appropriate protections — disabling advertising features, limiting data collection, and applying COPPA rules.

```xml
<application ...>
    <!-- Declare child-directed treatment for Google Play Services -->
    <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="[OMIT THIS TAG — only needed if AdMob is present]" />

    <!-- Child-directed treatment for any Google service that reads this flag -->
    <!-- This should be set programmatically at runtime as well (see Section 3.2) -->
    <meta-data
        android:name="com.google.android.gms.games.APP_ID"
        android:value="@string/app_id" />
</application>
```

**Note on AdMob:** The `com.google.android.gms.ads.APPLICATION_ID` meta-data tag is **only required if AdMob is integrated**. Since Bubble Reef Rush has no ads, this tag must NOT be present. Adding it without AdMob causes a runtime crash. If AdMob is ever added in a future update, this tag becomes mandatory — and the tag for child-directed treatment must also be added.

### 3.2 Runtime Child-Directed Treatment (Code, Not Manifest)

Google Play Games Services requires the child-directed flag to be set at runtime, not just in the manifest. Add this to your game's initialization code (in Godot, via a GDExtension or Java plugin):

```java
// In your Android plugin initialization or MainActivity.java
// Set before initializing any Google Play Service

// For Google Play Games Services:
GamesClient gamesClient = Games.getGamesClient(activity, account);
// GPGS respects Google Family Link by default for child accounts

// If Google Mobile Ads SDK is ever added:
RequestConfiguration requestConfiguration = new RequestConfiguration.Builder()
    .setTagForChildDirectedTreatment(RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_TRUE)
    .setTagForUnderAgeOfConsent(RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_TRUE)
    .setMaxAdContentRating(RequestConfiguration.MAX_AD_CONTENT_RATING_G)
    .build();
MobileAds.setRequestConfiguration(requestConfiguration);
```

### 3.3 Google Play Families Opt-In (Play Console, Not Manifest)

The Google Play Families program opt-in is configured in **Play Console**, not in the manifest:

Play Console → App content → Target audience and content → Select ages 6-8 and 9-12

This is a separate step from the manifest. However, it interacts with the manifest — Google's Play Console review checks the manifest for prohibited permissions (like `AD_ID`) and prohibited SDKs when you apply to the Families program.

---

## Section 4: Godot 4.3 Specific Notes

### 4.1 Permissions Godot Adds Automatically

When using the standard Godot Android export (no custom build), Godot adds the following permissions based on export settings:

| Permission | Godot Trigger | Action |
|-----------|--------------|--------|
| `android.permission.INTERNET` | Any network feature enabled | Keep — needed for GPGS and IAP |
| `android.permission.ACCESS_NETWORK_STATE` | Network checks | Keep — used for offline badge |
| `android.permission.VIBRATE` | Godot Input → Vibration enabled | Keep (optional, harmless) |
| `android.permission.WAKE_LOCK` | Audio playback (some Godot versions) | Review — not needed for kids app; remove if present |
| `android.permission.READ_EXTERNAL_STORAGE` | Old Godot versions; media feature | Must remove — not needed |
| `android.permission.WRITE_EXTERNAL_STORAGE` | Old Godot versions; save feature | Must remove — Godot saves to internal app storage |

**Action:** Use a custom Android build. Inspect the final manifest before every release using `apkanalyzer manifest permissions app-release.apk`. Remove any unexpected permissions.

### 4.2 Permissions That Require Manual Addition

These are NOT added by Godot automatically and must be added manually via a custom build or manifest additions file:

| Permission | How to Add | Notes |
|-----------|-----------|-------|
| `com.android.vending.BILLING` | Added by Godot Google Play Billing plugin | Verify it is present after adding the plugin |
| `android.permission.ACCESS_NETWORK_STATE` | Godot Export → Custom permissions | Should be auto-added; verify |

### 4.3 Manifest Additions File (No Custom Build Option)

If you are NOT using a custom Android build, you can add manifest snippets via Godot's export preset. In the Export dialog:

- Go to: Export → Android preset → Options → Custom Build
- In the "Gradle Build" section, set "Custom Build" to enabled
- Alternatively, use "Manifest additions" (a limited XML snippet that merges into the generated manifest)

**For a production Families-compliant app, the full custom build is strongly recommended** over manifest additions, because additions cannot remove permissions that Godot auto-adds.

### 4.4 Godot 4.3 Export Checklist

| Export Setting | Recommended Value | Notes |
|---------------|------------------|-------|
| Min SDK version | 21 (Android 5.0) | Covers 99%+ of Android devices. GPGS requires min 21. |
| Target SDK version | 34 (Android 14) or latest | Google Play requires targeting current Android SDK. |
| Use Custom Build | Yes | Required for full manifest control |
| Internet permission | Enabled | Required for GPGS and IAP |
| Access Network State | Enabled | Required for offline detection |
| Vibration | Enabled (optional) | Harmless haptic feature |
| AD_ID permission | Disabled / not present | Critical — must be absent for Kids app |
| Screen orientation | Portrait | Match game design (1080×1920) |
| Support large screens | Optional | Test on tablets |
| Export format | AAB (Android App Bundle) | Required by Google Play since 2021 |

### 4.5 App Bundle vs APK

Google Play requires Android App Bundles (`.aab`) for new apps. Godot 4.3 supports AAB export. Use the AAB format:

- Project → Export → Android → Export Project (AAB)
- Do NOT submit a plain `.apk` for new Google Play listings

---

## Section 5: Complete Annotated Manifest Template

The following is a minimal but complete `AndroidManifest.xml` template for Bubble Reef Rush. Use this as the base for your custom Android build.

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    package="com.[yourstudio].bubblereefinrush">

    <!-- ============================================================
         PERMISSIONS — INCLUDE
         ============================================================ -->

    <!-- Required: Google Play Billing for IAP -->
    <uses-permission android:name="com.android.vending.BILLING" />

    <!-- Required: Network access for GPGS cloud save and IAP verification -->
    <uses-permission android:name="android.permission.INTERNET" />

    <!-- Required: Detect network state for offline badge -->
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- Optional: Haptic feedback -->
    <uses-permission android:name="android.permission.VIBRATE" />

    <!-- ============================================================
         PERMISSIONS — DO NOT ADD
         These are listed here as a reminder to NOT include them.
         Remove any of these if Godot or a plugin adds them.
         ============================================================
         android.permission.ACCESS_FINE_LOCATION      — PROHIBITED (kids app)
         android.permission.ACCESS_COARSE_LOCATION    — PROHIBITED (kids app)
         com.google.android.gms.permission.AD_ID      — PROHIBITED (kids app / no ads)
         android.permission.READ_CONTACTS             — NOT NEEDED
         android.permission.RECORD_AUDIO              — NOT NEEDED
         android.permission.CAMERA                    — NOT NEEDED
         android.permission.READ_PHONE_STATE          — NOT NEEDED
         android.permission.READ_EXTERNAL_STORAGE     — NOT NEEDED
         android.permission.WRITE_EXTERNAL_STORAGE    — NOT NEEDED
         android.permission.GET_ACCOUNTS              — NOT NEEDED
         android.permission.WAKE_LOCK                 — NOT NEEDED (remove if Godot adds)
         ============================================================ -->

    <application
        android:name=".BubbleReefRushApp"
        android:icon="@mipmap/icon"
        android:roundIcon="@mipmap/icon"
        android:label="@string/godot_project_name_string"
        android:allowBackup="true"
        android:fullBackupContent="@xml/backup_rules"
        android:usesCleartextTraffic="false"
        android:networkSecurityConfig="@xml/network_security_config"
        android:supportsRtl="true"
        android:hardwareAccelerated="true"
        android:requestLegacyExternalStorage="false"
        tools:targetApi="33">

        <!-- Google Play Games Services App ID (required for GPGS) -->
        <meta-data
            android:name="com.google.android.gms.games.APP_ID"
            android:value="@string/app_id" />

        <!-- DO NOT add com.google.android.gms.ads.APPLICATION_ID
             unless AdMob is integrated. Adding it without AdMob crashes the app. -->

        <!-- Main Activity — Godot GodotApp -->
        <activity
            android:name="com.godot.game.GodotApp"
            android:exported="true"
            android:launchMode="singleInstancePerTask"
            android:configChanges="orientation|keyboardHidden|screenSize|smallestScreenSize|density|keyboard|navigation|screenLayout|uiMode"
            android:resizeableActivity="false"
            android:screenOrientation="portrait"
            android:theme="@style/GodotAppSplashTheme">

            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>

        </activity>

    </application>

</manifest>
```

---

## Section 6: Pre-Release Manifest Verification Checklist

Run these checks before every release build:

```bash
# 1. Decode the final APK/AAB manifest and check permissions
apkanalyzer manifest permissions app-release.aab

# 2. Verify AD_ID permission is NOT present (must return no results)
apkanalyzer manifest print app-release.aab | grep -i "ad_id"
# Expected output: (nothing)

# 3. Verify location permissions are NOT present
apkanalyzer manifest print app-release.aab | grep -i "location"
# Expected output: (nothing)

# 4. Verify usesCleartextTraffic is false
apkanalyzer manifest print app-release.aab | grep -i "cleartext"
# Expected output: android:usesCleartextTraffic="false"

# 5. Verify BILLING permission IS present
apkanalyzer manifest print app-release.aab | grep -i "billing"
# Expected output: com.android.vending.BILLING

# 6. Run Google Play pre-launch report
# Upload AAB to Play Console internal track → Pre-launch report tab
# Review security and policy findings before promoting to production
```

---

## Summary: Must-Have / Must-Omit Quick Reference

| Item | Include? | Reason |
|------|---------|--------|
| `BILLING` permission | YES | Required for IAP |
| `INTERNET` permission | YES | Required for GPGS / IAP |
| `ACCESS_NETWORK_STATE` | YES | Required for offline detection |
| `VIBRATE` | Optional | Haptic feedback |
| `AD_ID` permission | NO — OMIT | Google Play Families: prohibited for child-directed apps |
| `ACCESS_FINE_LOCATION` | NO — OMIT | COPPA: prohibited without verifiable parental consent |
| `ACCESS_COARSE_LOCATION` | NO — OMIT | Same reasoning |
| `RECORD_AUDIO` / `CAMERA` | NO — OMIT | Not needed; alarming to parents |
| `READ_PHONE_STATE` | NO — OMIT | Not needed; accesses persistent device IDs |
| `usesCleartextTraffic="false"` | YES | Google Play security requirement |
| `allowBackup="true"` with rules | YES (recommended) | Lets players recover save data |
| `networkSecurityConfig` | YES | Enforces HTTPS-only |
| GPGS `APP_ID` meta-data | YES | Required for Google Play Games Services |
| AdMob `APPLICATION_ID` meta-data | NO — OMIT | Only add if AdMob is integrated; crashes without it |
| Export format: AAB | YES | Required by Google Play |

---

*End of Android Manifest Flags Reference v1.0 — Bubble Reef Rush*
*Prepared by QA-2. Not legal advice. Verify against current Android and Google Play documentation at time of build.*
