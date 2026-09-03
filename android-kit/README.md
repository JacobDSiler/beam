# Beam Android build kit

Everything you need to turn `index.html` into a signed `.aab` for the Google Play Console.

## One-time prerequisites (install these once)

1. **Node.js 18+** — you probably already have this via nvm. `node -v` to check.
2. **Java JDK 17** — Android Gradle Plugin 8.x needs 17. `java -version`.
   Install via [Adoptium Temurin 17](https://adoptium.net/temurin/releases/?version=17) if missing.
3. **Android Studio** — easiest way to get the Android SDK + Platform 34 + Build Tools + `sdkmanager`. Install from [developer.android.com/studio](https://developer.android.com/studio). Open once, let it download the SDK, then close it. You don't have to build from Android Studio; the command line works.
4. Set `ANDROID_HOME` env var to your SDK location (Android Studio shows it in Settings → SDK Manager, usually `%LOCALAPPDATA%\Android\Sdk`).

Verify:
```
node -v         # >= 18
java -version   # 17.x
echo %ANDROID_HOME%   # points to your SDK
```

## Google Play Console prerequisites

- **Developer account** — $25 one-time at [play.google.com/console](https://play.google.com/console). Personal or organization; personal is cheaper but has the 20-tester closed-testing requirement for new apps.
- **Identity verification** — Google now requires government ID + address verification for new accounts. Start this early; it can take days.
- **Privacy policy URL** — publicly hosted. `android-kit/privacy-policy.md` is a draft you can publish at `https://beam.jacobsiler.com/privacy.html` on your existing GitHub Pages site.

## First-time build (walk through once)

From `C:\dev\beam` in a terminal:

```
npm install                    # installs Capacitor + assets tools
npm run android:init           # generates android/ folder + applies Beam customizations
```

Then generate a signing key ONCE (see `keystore-instructions.md` for details):

```
keytool -genkey -v -keystore beam-upload.jks -alias beam-upload -keyalg RSA -keysize 4096 -validity 10000
```

Move `beam-upload.jks` to a safe location OUTSIDE the repo (e.g. `%USERPROFILE%\.android-keys\`). Then create `android/key.properties`:

```
storeFile=C:/Users/serpe/.android-keys/beam-upload.jks
storePassword=YOUR_KEYSTORE_PASSWORD
keyAlias=beam-upload
keyPassword=YOUR_KEY_PASSWORD
```

Generate app icons from the source SVG:

```
npm run icons
```

Build the release AAB:

```
npm run android:build:win      # Windows (uses gradlew.bat)
# or on WSL / mac / linux:
npm run android:build
```

Output goes to `android/app/build/outputs/bundle/release/app-release.aab`.

## Subsequent builds (after web changes)

Every time you edit `index.html` and want a new Android release:

1. Bump the version in `android/app/build.gradle`:
   - `versionCode` — integer, must strictly increase (1 → 2 → 3 → ...)
   - `versionName` — semver-ish human string ("0.1.0", "0.1.1", ...)
2. `npm run android:build:win`
3. Upload the new `.aab` in Play Console → your app → Release → Production → Create new release.

## Play Console listing

`android-kit/play-listing.md` has ready-to-paste copy for:
- App name
- Short description (80 char)
- Full description (< 4000 char)
- Category + tags
- Data safety declarations (Beam is E2E encrypted; declare it correctly)
- Content rating questionnaire answers
- Permission justifications
- What's new / release notes

## Screenshots

Play Console wants 2-8 phone screenshots. Simplest way to produce them:
- Install the built .aab on your phone via `adb install app-release.aab` (or upload to Internal Testing track and install via Play link)
- Take screenshots in-app with Volume-down + Power
- Recommended shots: home screen, mailbox with items, vault, in-a-call, camera capture, encryption banner in an unencrypted box

## Troubleshooting

- **"SDK location not found"** — `ANDROID_HOME` isn't set or points to the wrong place.
- **"Java compile targets 8 but source is 17"** — you have JDK 8 as default. Set `JAVA_HOME` to your JDK 17.
- **"Duplicate class org.jetbrains.kotlin..."** — usually a stale `android/.gradle` cache. Delete `android/.gradle` and rebuild.
- **Signed AAB rejected as "debug"** — you're building `bundleDebug` or your key.properties isn't being read. Verify the file exists at `android/key.properties` (case-sensitive).
