# Beam — Privacy Policy

_Last updated: [PUBLISH DATE]_

Beam is a private mailbox and file vault built for people who need a
communication channel their situation can't tolerate them losing — including
people navigating coercive control, stalking, or intimate partner abuse.
Privacy is not a marketing point; it is the product.

This policy describes what Beam does with your data.

## What Beam collects

**Content you put into a mailbox.** Messages you type, files you upload, voice
messages you record, video messages you record, and photos you capture in the
app. All such content is **end-to-end encrypted on your device before it is
sent to our storage backend.** The encryption key is derived from the mailbox
passcode using PBKDF2-SHA256 (200,000 iterations) and a random per-mailbox
salt. Your passcode never leaves your device.

**Mailbox metadata.** For each item we store the creation timestamp, item
type (message / file / voice / video / photo), file size, MIME type, and
optional expiry date. These are not encrypted because they are required for
the app to sort, expire, and display your items.

**A short-lived "pending call" signal** when you call another participant.

We do **not** collect:

- Your real name, email address, phone number, or physical address.
- Your device's advertising identifier.
- Location data of any kind.
- Contacts, calendars, or files outside the app.
- Analytics of how you use the app.
- Any information from any tracker or advertising SDK. Beam ships no
  advertising or analytics SDKs.

## Who can read your content

- **You**, using the mailbox code and the mailbox passcode.
- **Anyone you deliberately share the mailbox code AND passcode with.**
- **Nobody else — including us.** We store only ciphertext. Without the
  passcode, the data on our servers is opaque random bytes to us and to
  anyone who ever compromises our storage.

Mailboxes without a passcode are **not encrypted at rest**. The app displays a
red banner warning you when this is the case. Use a passcode.

## Where your data lives

Beam's storage backend is Google Firebase Firestore (project
`miscellaneous-117e9`), operated by Google LLC in Google Cloud data centers.
When you use Beam, encrypted content transits Google Cloud infrastructure. See
Google's privacy documentation at
<https://policies.google.com/privacy> for their handling of the ciphertext
they store on our behalf. Google does not have the ability to decrypt your
mailbox contents.

## Peer-to-peer transfers

When two Beam clients are connected simultaneously, files can be transferred
directly between them via WebRTC data channels (DTLS-encrypted). Peer
transfers do not touch Firestore. IP addresses of both peers are exchanged
via ICE candidate signaling in order to establish the direct link; this is
inherent to WebRTC and cannot be avoided if peer-to-peer is used.

## Permissions the app requests

- **Internet** — required to sync with the storage backend.
- **Camera** — used only when you tap the camera button to capture a photo or
  start a video call. Camera streams are never uploaded automatically.
- **Microphone** — used only when you record a voice message or start a call.
  Audio streams are never uploaded automatically.

Beam does not request any other permissions.

## Data retention

Items you put into a mailbox stay until:
- The item's per-item expiry date passes (if you set one), OR
- The mailbox's default TTL passes (if you set one at creation), OR
- You delete the item explicitly, OR
- You delete the mailbox.

You can export a mailbox's contents at any time (as .txt, .md, or .pdf) and
save them locally.

## Children

Beam is not directed at children under 13. We do not knowingly collect
information from children under 13.

## Changes to this policy

If Beam's data practices change materially, we will update this policy and
the "Last updated" date. Continued use after such an update means you accept
the revised policy.

## Contact

Questions about this policy: [YOUR CONTACT EMAIL]
