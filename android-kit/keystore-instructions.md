# Signing key setup — do this once, guard it forever

Google Play requires a signed AAB. You generate an **upload key** locally,
sign the AAB with it, and Play accepts + re-signs internally with its own
**app signing key**. That means:

- If you lose your upload key you can request a reset from Google.
- If you lose Google's key, they still have it — you're safe.

But losing the upload key while it's still in use is painful, so treat it
like the family keys to the safe.

## Generate the upload key (one time only)

```
keytool -genkey -v ^
  -keystore beam-upload.jks ^
  -alias beam-upload ^
  -keyalg RSA -keysize 4096 ^
  -validity 10000
```

- `keytool` ships with the JDK.
- 10,000-day validity is Google's recommendation (~27 years).
- You'll be prompted for two passwords: keystore password and key password. Use different strong random strings for both (a password manager is right here).
- You'll be prompted for name / org / locality. Any real-ish values are fine; users never see them.

## Store it somewhere sensible

**NOT in the git repo.** The `.gitignore` blocks `*.jks` and `key.properties`, but that's a safety net, not a plan.

Recommended: `%USERPROFILE%\.android-keys\beam-upload.jks`. Then also:
- Copy the file to a USB drive kept somewhere physically safe.
- Save both passwords in your password manager (1Password / Bitwarden / etc.), tagged so future you can find them.
- If this app matters legally, keep a second offline copy in a safe deposit box.

## Point Gradle at the key

Create `android/key.properties` (this file is `.gitignore`d):

```
storeFile=C:/Users/serpe/.android-keys/beam-upload.jks
storePassword=YOUR_KEYSTORE_PASSWORD
keyAlias=beam-upload
keyPassword=YOUR_KEY_PASSWORD
```

Note:
- Use forward slashes even on Windows (Gradle prefers them).
- The absolute path in `storeFile` is what matters — Gradle needs to find the file at build time.

## Sanity-check before your first Play upload

After running `npm run android:build:win`, verify the signature:

```
cd android\app\build\outputs\bundle\release
jarsigner -verify -verbose -certs app-release.aab
```

You should see `jar verified.` and your certificate CN. If instead it says `unsigned`, your `key.properties` isn't being read — check the path is correct and the file has no BOM or stray whitespace.

## When Google Play asks for your SHA-256 fingerprint

Some Play features (App Links, Firebase integration) ask for the upload key's SHA-256. Get it with:

```
keytool -list -v -keystore C:\Users\serpe\.android-keys\beam-upload.jks -alias beam-upload
```

Look for the `SHA256:` line under Certificate fingerprints.
