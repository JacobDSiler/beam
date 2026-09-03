// customize-android.js
// Runs once after `npx cap add android` generates the android/ folder from
// Capacitor's template. Patches the generated files with Beam-specific
// customizations that Capacitor doesn't infer from capacitor.config.json.
//
// Idempotent — safe to re-run. If you ever delete + re-generate android/,
// re-run this script afterward.
const fs = require('fs');
const path = require('path');

const REPO = path.resolve(__dirname, '..');
const ANDROID = path.join(REPO, 'android');
const APP = path.join(ANDROID, 'app');

if (!fs.existsSync(ANDROID)) {
  console.error('customize-android: android/ folder does not exist yet. Run `npx cap add android` first.');
  process.exit(1);
}

function patch(file, replacers) {
  const full = path.join(APP, file);
  if (!fs.existsSync(full)) { console.error(`  MISS: ${file}`); return; }
  let src = fs.readFileSync(full, 'utf8');
  let changed = 0;
  for (const [find, rep] of replacers) {
    if (src.includes(rep)) continue; // already patched (idempotency)
    if (typeof find === 'string') {
      if (!src.includes(find)) { console.error(`  anchor not found in ${file}: ${find.slice(0,60)}...`); continue; }
      src = src.replace(find, rep);
    } else {
      // regex
      if (!find.test(src)) { console.error(`  regex not matched in ${file}: ${find}`); continue; }
      src = src.replace(find, rep);
    }
    changed++;
  }
  if (changed) {
    fs.writeFileSync(full, src);
    console.log(`  patched (${changed}): ${file}`);
  } else {
    console.log(`  no-op: ${file}`);
  }
}

// ---- AndroidManifest.xml ----
//  * Camera + microphone permission declarations
//  * hardware feature declarations (optional so devices without a cam still install)
//  * FLAG_SECURE-friendly config in application tag
console.log('AndroidManifest.xml');
patch('src/main/AndroidManifest.xml', [
  [
    '<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
    '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n' +
    '    <!-- Beam permissions: minimal on purpose -->\n' +
    '    <uses-permission android:name="android.permission.INTERNET" />\n' +
    '    <uses-permission android:name="android.permission.CAMERA" />\n' +
    '    <uses-permission android:name="android.permission.RECORD_AUDIO" />\n' +
    '    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />\n' +
    '    <!-- Camera + mic are optional so tablets/desktops without them still install -->\n' +
    '    <uses-feature android:name="android.hardware.camera" android:required="false" />\n' +
    '    <uses-feature android:name="android.hardware.microphone" android:required="false" />\n'
  ]
]);

// ---- app/build.gradle ----
//  * versionCode / versionName pinning
//  * enable minifyRelease for release builds
//  * signing config hook that reads android/key.properties (created by user)
console.log('app/build.gradle');
patch('build.gradle', [
  // Insert signing config block after the android { block opens.
  [
    'android {',
    'def keystorePropertiesFile = rootProject.file("key.properties")\n' +
    'def keystoreProperties = new Properties()\n' +
    'if (keystorePropertiesFile.exists()) {\n' +
    '    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n' +
    '}\n\n' +
    'android {'
  ],
  // Hook the signing config + release build type. We insert BEFORE `buildTypes {`.
  [
    'buildTypes {',
    'signingConfigs {\n' +
    '        release {\n' +
    '            if (keystoreProperties.containsKey("storeFile")) {\n' +
    '                storeFile     file(keystoreProperties["storeFile"])\n' +
    '                storePassword keystoreProperties["storePassword"]\n' +
    '                keyAlias      keystoreProperties["keyAlias"]\n' +
    '                keyPassword   keystoreProperties["keyPassword"]\n' +
    '            }\n' +
    '        }\n' +
    '    }\n' +
    '    buildTypes {'
  ],
  // Attach signingConfig to the release block if missing
  [
    /release \{\s*minifyEnabled false/,
    'release {\n            signingConfig signingConfigs.release\n            minifyEnabled false'
  ]
]);

// ---- android/app/src/main/res/values/strings.xml ----
// Ensure the human-readable app label matches capacitor.config.json.
console.log('res/values/strings.xml');
patch('src/main/res/values/strings.xml', [
  [
    /<string name="app_name">[^<]*<\/string>/,
    '<string name="app_name">Beam</string>'
  ],
  [
    /<string name="title_activity_main">[^<]*<\/string>/,
    '<string name="title_activity_main">Beam</string>'
  ]
]);

console.log('\nDone. Next steps:');
console.log('  1. Create android/key.properties with your keystore info (see android-kit/keystore-instructions.md)');
console.log('  2. npm run icons     (generates all icon densities from android-kit/assets/icon.png)');
console.log('  3. npm run android:build  (produces android/app/build/outputs/bundle/release/app-release.aab)');
