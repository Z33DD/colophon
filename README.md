<p align="center">
  <img src="docs/icon/icon.png" alt="Colophon icon" width="100" />
</p>

# Colophon

Colophon is an Android app for your self-hosted [Calibre-Web](https://github.com/janeczku/calibre-web) library and its forks ([Calibre-Web Automated](https://github.com/crocodilestick/Calibre-Web-Automated), [Calibre-Web-NextGen](https://github.com/new-usemame/Calibre-Web-NextGen), Grimmory), plus the Calibre content server and plain OPDS. Browse your collection as a wall of covers, see each book's state at a glance, and get from opening the app to reading in as few taps as possible.

> **Colophon is a fork of [Calibre Web Companion](https://github.com/doen1el/calibre-web-companion) by [doen1el](https://github.com/doen1el).** Nearly all of the server integration, reader, sync and offline work comes from that project. Colophon redesigns the interface and navigation on top of it. Thank you to its author and contributors. Like the original, Colophon is licensed under the [GNU GPL v3](LICENSE).

It is an unofficial client and is not affiliated with the Calibre or Calibre-Web projects.

## What Colophon changes

- **Navigation:** Library, Discover and On device (plus Requests for Shelfmark). Account and settings sit behind your avatar.
- **Library:** a cover wall with state stamps (Read, On device), one-tap filters (Unread, Read, Format), visible sort, and search that understands authors, series and tags.
- **Book details:** one main action (Read, or Download), labelled secondary actions, and everything else under More. Read and Archived are toggles that show the current state.
- **Downloads:** progress on the button, an Open action when done, a download folder you choose once, and opening the copy already on your phone.
- **Accessibility:** follows the system font size, screen-reader labels, 48dp targets, and an e-ink mode that renders pure black on white without motion.
- **Look:** a new visual identity ("Circulation Desk"); wallpaper colours and custom colours stay available.

## Install

Download the APK from [Releases](../../releases) and install it. Colophon has its own package id (`io.github.z33dd.colophon`), so it installs next to Calibre Web Companion.

## Features

- Connect to your Calibre-Web (Automated), Grimmory, Calibre and OPDS servers, including reverse proxy/SSO setups, custom HTTP headers and self-signed certificates.
- Browse your whole library with smooth, fast navigation.
- Discover books by category, authors, series, publishers, ratings, hot & trending, and more.
- View rich details for every book, edit its metadata, and upload new covers.
- Mark books as read or unread, archive them, and organize them into shelves.
- Create, edit and browse Magic Shelves, dynamic, rule‑based shelves (Calibre‑Web Automated & Calibre-Web-NextGen only).
- Add books quickly by scanning their ISBN barcode.
- Read EPUB, PDF and CBZ books in the built-in reader without leaving the app. Books are fetched only when you open them, kept on the device up to a storage limit you choose, and automatically marked as read when you finish them.
- Sync your reading progress across devices with KOReader Sync or your own WebDAV server (see [Reading progress sync](#-reading-progress-sync)).
- Send books to your e‑reader via [BookDrop](https://bookdrop.cc) (or your own instance) or Calibre‑Web's email function.
- Download books straight into your collection with [shelfmark](https://github.com/calibrain/shelfmark).
  - ⚠️ This app does **not** support, encourage or facilitate the piracy of copyrighted works. Please only download content you are legally entitled to, respecting copyright is your responsibility.
- Upload books to your Calibre‑Web server.
- Sync your whole library or selected books for offline reading.
- Check your collection statistics at a glance.
- Make it yours: reorder or hide book actions, detail sections and Discover sections, choose a theme, enable e‑ink mode, and adjust the text size, available in 15 languages (new strings in English first).

## Reading progress sync

Stock Calibre-Web has no API for reading positions, so progress is synced through one of these:

| Method | Works with | Notes |
|---|---|---|
| KOReader Sync | Calibre-Web-Automated, Calibre-Web-NextGen | Built into the server, also syncs with KOReader devices. Enable it under *Settings → Reader*. EPUB only. |
| WebDAV | Any server | Needs your own WebDAV storage (e.g. Nextcloud). Syncs EPUB, PDF and CBZ positions between devices running the app. |
| Read status | Calibre-Web and its forks | Books are marked as read on the server when you reach the end in the internal reader. |

> **OPDS:** OPDS catalogs can be browsed, downloaded and read, but the protocol is read-only. To edit metadata, use shelves or sync read status with Calibre-Web (or a fork), log in with the *Calibre Web* server type instead of OPDS.

## Building

```sh
flutter pub get
flutter build apk --release
```

Release signing reads `android/key.properties` (gitignored) or the `COLOPHON_KEYSTORE`, `COLOPHON_KEY_ALIAS`, `COLOPHON_STORE_PASSWORD` and `COLOPHON_KEY_PASSWORD` environment variables. Without them the release APK is left unsigned. The launcher icon is drawn in code: `flutter test tool/render_icon_test.dart && dart run flutter_launcher_icons && tool/monochrome_icons.sh`.

## Credits

- [Calibre Web](https://github.com/janeczku/calibre-web)
- [Calibre Web Automated](https://github.com/crocodilestick/Calibre-Web-Automated)
- [shelfmark](https://github.com/calibrain/shelfmark)
- [BookDrop](https://github.com/eitan12345om/book-drop)
- [Flutter](https://github.com/flutter/flutter)
- [Weblate](https://hosted.weblate.org/)
- [CosmosEpub](https://github.com/Mamasodikov/cosmos_epub)
- [pdfx](https://github.com/ScerIO/packages.flutter/tree/main/packages/pdfx)
- [Calibre Web Companion](https://github.com/doen1el/calibre-web-companion) by doen1el: the project Colophon is forked from.
