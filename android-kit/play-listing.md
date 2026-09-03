# Play Console listing — ready-to-paste content

Every field below is sized to Play Console's limits. Edit `[BRACKETED]`
placeholders before pasting.

---

## Store settings

**App name** (30 char max):

```
Beam
```

**Short description** (80 char max):

```
Private, encrypted mailbox & vault. Built for people who cannot afford leaks.
```

_(78 characters. Alternative if you want to be more explicit about the DV use case:_
`Encrypted mailbox for people in coercive-control or DV situations.` _— 66 chars.)_

**Full description** (4000 char max — this is ~1600):

```
Beam is a small, focused mailbox and file vault built for people who cannot
afford leaks — including people navigating coercive control, stalking, or
intimate partner abuse. Nothing about Beam depends on trust in the app maker.

WHAT IT DOES
• Create a private mailbox with a code and a passcode.
• Send yourself or trusted contacts text messages, files, voice notes, video
  notes, and photos captured in-app.
• Move sensitive items into a locked Vault inside the mailbox.
• Voice + video calls when both sides are online.
• Share files directly device-to-device via peer transfer when possible,
  falling back to secure cloud storage otherwise.
• Export a mailbox's contents to text, markdown, or PDF at any time.

WHAT MAKES IT DIFFERENT
• End-to-end encrypted. Your messages, files, and voice/video are encrypted
  on your device before they ever leave it, using a key derived from your
  passcode. The people who host the storage cannot read them. We cannot
  read them. The passcode never leaves your device.
• Session lock. The mailbox re-prompts for the passcode after two minutes of
  idle, and always after fifteen minutes, regardless of activity — so
  someone who gets brief access to an unlocked screen cannot browse.
• Zero trackers. No analytics, no advertising, no third-party SDKs beyond
  the storage backend itself.
• Minimal permissions. Internet, camera, and microphone only — and camera
  and microphone only when you actively tap to use them.
• Nothing hidden. Beam is a single, auditable HTML application.

FOR WHOM
Beam is for anyone whose safety depends on a private channel: survivors
building a record of an abusive relationship, people isolated by
controlling partners who need a lifeline to trusted contacts, journalists,
sources, therapists' clients working through sensitive material — anyone
for whom "just use a normal app" is not a safe answer.

WHAT IT IS NOT
Beam is not a full messenger and does not attempt to be. It has no phone
directory, no push notifications by default, no read receipts, no
presence. It is a mailbox: you put things in, they wait, you take them out.

Feedback and issues: [YOUR CONTACT EMAIL OR REPO LINK]
```

---

## Category, tags, contact

- **Category:** Communication
- **Tags:** Messaging, Privacy, File sharing
- **Website:** `https://beam.jacobsiler.com`
- **Email:** `[YOUR CONTACT EMAIL]` (must be reachable)
- **Privacy policy URL:** `https://beam.jacobsiler.com/privacy.html` — publish `android-kit/privacy-policy.md` at this URL before submitting.

---

## Content rating questionnaire

- Does the app contain violence? **No**
- Sexual content? **No**
- Drug/alcohol/tobacco references? **No**
- User-generated content (UGC)? **Yes — text messages, files, voice, video, photos exchanged between users.**
  - Can users interact? **Yes** (peer-to-peer inside the mailbox)
  - Can users share their location? **No**
  - Purchase digital content? **No**
- Simulated gambling? **No**
- Miscellaneous — does the app contain any of these features? **User-generated content messaging.**

Expected rating: **PEGI 12 / ESRB Teen / IARC-equivalent.** UGC bumps you past "Everyone" because content is user-controlled.

---

## Target audience

- **Age group:** 18+ (given the DV/abuse context, don't market to minors)
- **Made for kids?** No

---

## Data safety declarations (this is the important one)

Google's data-safety form is public and legally binding. Answer honestly:

**Does your app collect or share any of the required user data types?** **Yes.**

For each data type below, declare: **Collected**, **Not shared with third parties**, **Encrypted in transit**, and **Encrypted at rest** where applicable.

| Data type | Collected? | Shared? | Encrypted in transit | Encrypted at rest | Optional? | Purpose |
|---|---|---|---|---|---|---|
| Messages (in-app) | Yes | No | Yes (TLS) | **Yes (E2E, app-level)** | No | App functionality |
| Files & docs | Yes | No | Yes | **Yes (E2E)** | Yes | App functionality |
| Photos | Yes | No | Yes | **Yes (E2E)** | Yes | App functionality |
| Videos | Yes | No | Yes | **Yes (E2E)** | Yes | App functionality |
| Voice / audio | Yes | No | Yes | **Yes (E2E)** | Yes | App functionality |
| App activity / interactions | No | | | | | |
| Diagnostics / crash logs | No | | | | | |
| Personal info (name, email, ID) | No | | | | | |
| Location | No | | | | | |
| Contacts | No | | | | | |
| Device or advertising IDs | No | | | | | |

Also answer:
- **Does your app allow users to request deletion?** Yes — deleting a mailbox removes all its items. Note this in the "Data deletion" field.
- **Committed to Play's Families policy?** N/A (app is not directed at children).

---

## Permission justifications

Play may ask why you request each permission. Copy-paste-ready:

- **CAMERA** — "Used only when the user taps the in-app camera button to capture a photo, or starts a video call. Camera frames are never captured automatically or in the background."
- **RECORD_AUDIO** — "Used only when the user taps the record button to leave a voice message, or starts a voice/video call. Audio is never captured in the background."
- **INTERNET** — "Required to sync encrypted mailbox contents with the storage backend."

---

## App access

If your closed testing track requires it — **credentials for testers**:

- Test mailbox code: `[create one and put it here]`
- Test mailbox passcode: `[same]`

Set the box's item TTL to a short window (e.g. 24h) so test content auto-expires.

---

## What's new (release notes for v0.1.0)

```
First public build.
• Encrypted mailbox + vault
• Voice, video, and photo capture
• Peer-to-peer file transfer when a peer is online
• Session lock after 2 min idle / 15 min max
• Export contents to .txt, .md, or .pdf
```
