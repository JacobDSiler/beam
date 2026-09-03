// prep-web.js
// Stages the web assets into www/ so Capacitor's `cap sync` copies exactly
// those files (and nothing else) into the Android project's assets folder.
// Run automatically by `npm run android:build` and `npm run android:sync`.
const fs = require('fs');
const path = require('path');

const REPO = path.resolve(__dirname, '..');
const WWW  = path.join(REPO, 'www');

const FILES_TO_COPY = [
  'index.html',
  // add other web files here as they appear (e.g. any future .css / .js / images)
];

if (!fs.existsSync(WWW)) fs.mkdirSync(WWW, { recursive: true });

// Clean www first so a removed file at repo root also disappears from the app
for (const f of fs.readdirSync(WWW)) {
  const p = path.join(WWW, f);
  if (fs.statSync(p).isDirectory()) fs.rmSync(p, { recursive: true, force: true });
  else fs.rmSync(p);
}

for (const f of FILES_TO_COPY) {
  const src = path.join(REPO, f);
  if (!fs.existsSync(src)) {
    console.error(`prep-web: missing ${src}`);
    process.exit(1);
  }
  const dst = path.join(WWW, f);
  fs.copyFileSync(src, dst);
  const sz = (fs.statSync(dst).size / 1024).toFixed(1);
  console.log(`prep-web: ${f}  (${sz} KB)`);
}
console.log(`prep-web: staged ${FILES_TO_COPY.length} file(s) -> ${WWW}`);
