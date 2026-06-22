<<<<<<< HEAD
# Bulbul 🐦‍⬛

A minimalist book discovery & reading app — pure-black, monochrome, Nothing-OS /
Spotify / Kindle inspired. Search millions of books, read public-domain titles
in-app (EPUB + HTML), favorite what you love, and pick up exactly where you left
off.

Built with Flutter 3 · Material 3 · Riverpod 3 · Dio · Hive · GoRouter.

---

## ✨ Features

- **Search** millions of books via Open Library, with debounced, as-you-type
  results that double as autocomplete suggestions (Spotify-style) and lazy
  pagination.
- **Book details** — large cover, author, year, page count, description and
  subjects.
- **Read in-app** public-domain books from **Project Gutenberg** (primary) with
  an **Internet Archive** fallback. EPUB and HTML are both supported.
- **Reader** with font-size & line-spacing controls, three reading themes
  (Dark / Dim / Sepia), chapter navigation, live reading percentage, and
  immersive tap-to-toggle chrome.
- **Continue Reading** — resume any book at the exact saved position across app
  launches.
- **Favorites** — add/remove, persisted locally, fully offline.
- Robust **empty / loading / offline / error** states with retry everywhere.

---

## 🏗 Architecture

Feature-first **Clean Architecture** with a shared core, top-level `models`,
`services`, `repositories` and DI `providers`, and self-contained `features`.

```
lib/
├── main.dart                     # Bootstrap: Hive init + ProviderScope + runApp
├── app.dart                      # Root MaterialApp.router (dark-only theme)
│
├── core/                         # Cross-cutting building blocks
│   ├── constants/                # api_constants, app_constants (boxes, spacing)
│   ├── theme/                    # app_colors, app_text_styles, app_theme (M3)
│   ├── network/                  # dio_client (+ DioSafeCall extension)
│   ├── error/                    # app_exception (thrown), failure (held in state)
│   ├── utils/                    # debouncer
│   ├── router/                   # route_paths, app_router, scaffold_with_nav_bar
│   └── widgets/                  # book_cover_image, app_state_views, section_header
│
├── models/                       # Strongly-typed entities
│   ├── book.dart (+ .g)          # Open Library search result
│   ├── author.dart (+ .g)        # Author metadata
│   ├── book_details.dart (+ .g)  # Open Library work record
│   ├── gutenberg_book.dart (+ .g)# Gutendex result (EPUB/HTML formats)
│   ├── archive_item.dart (+ .g)  # Internet Archive doc
│   ├── book_ref.dart             # Lightweight nav reference (Book ⇄ Favorite)
│   ├── readable_source.dart      # Resolved "where/how to read" + enums
│   ├── reader_document.dart      # Parsed, render-ready chapters
│   ├── favorite_book.dart        # Hive model (hand-written TypeAdapter, id 1)
│   └── reading_progress.dart     # Hive model (hand-written TypeAdapter, id 2)
│
├── services/                     # One responsibility each
│   ├── hive_service.dart         # Init + box lifecycle
│   ├── favorites_service.dart    # Favorites box CRUD
│   ├── reading_progress_service.dart
│   ├── open_library_service.dart # Search / suggestions / work details
│   ├── gutenberg_service.dart    # Gutendex search + readable-edition pick
│   ├── internet_archive_service.dart
│   └── content_parser.dart       # EPUB (isolate) + HTML → ReaderDocument
│
├── repositories/                 # Use-case orchestration over services
│   ├── book_repository.dart      # Discovery (Open Library)
│   ├── favorites_repository.dart
│   └── reading_repository.dart   # Source resolution + content load + progress
│
├── providers/
│   └── app_providers.dart        # Dependency-injection graph (Riverpod)
│
└── features/                     # Feature-first UI + feature providers
    ├── home/                     # Continue Reading + Favorites rails
    ├── search/                   # Debounced search + pagination
    ├── book_details/             # Details + Read / Favorite actions
    ├── reader/                   # EPUB/HTML reader + settings + progress
    └── favorites/                # Favorites grid
```

### Data flow

```
UI (ConsumerWidget)
  → feature provider (Notifier / FutureProvider)
    → repository  (book / favorites / reading)
      → service   (HTTP via Dio, or Hive)
        → model   (typed, JSON-serialized)
```

Errors are thrown as a normalized `AppException` in the network layer and
converted to an equatable `Failure` held in state, so widgets stay free of
`try/catch` and render `AppErrorView` (with offline detection + retry).

---

## 🌐 APIs used

| Source | Role | Endpoint |
| --- | --- | --- |
| Open Library | Metadata (search, works, covers) | `openlibrary.org/search.json`, `/works/{id}.json`, `covers.openlibrary.org` |
| Project Gutenberg (Gutendex) | Primary readable content | `gutendex.com/books?search=` |
| Internet Archive | Secondary readable content | `archive.org/advancedsearch.php`, `/metadata/{id}` |

---

## 🚀 Getting started

```bash
flutter pub get
dart run build_runner build      # generates *.g.dart JSON serializers
flutter run                      # Android / iOS recommended
flutter test                     # unit tests for the data layer
```

> **Note on platforms:** the app targets mobile (Android/iOS). A `flutter build
> web` compiles cleanly and is used in CI as a fast full-tree compile check, but
> the public book APIs don't all send CORS headers, so live data fetching is
> intended for mobile.

---

## 🧩 Notable engineering decisions

- **Hand-written Hive `TypeAdapter`s.** The legacy `hive_generator` pins an old
  `source_gen` that conflicts with modern `json_serializable`; rather than pin
  everything backwards, the two persisted models ship hand-written adapters that
  mirror the generator's binary layout.
- **EPUB parsing off the UI thread.** Unzip + XML parse runs in a `compute`
  isolate; only sendable primitives cross back.
- **Large HTML is chunked** into page-sized chapters so each `flutter_html`
  widget tree stays small and smooth.
- **Scroll-driven progress without jank.** The live reading percentage rebuilds
  via a `ListenableBuilder` on the scroll controller, never re-rendering the
  heavy chapter HTML.
- **Resume positions stored as a fraction** (0–1) within a chapter, so they
  survive font-size and screen-size changes.
- **Riverpod 3** unified-`Ref` API; all favorites/progress mutations route
  through notifiers that also subscribe to Hive, keeping every surface in sync.
=======
📚 Bulbul — Discover, save, and read books.
>>>>>>> 78d0edd3df8e259b293db869f95cc19c745d52d8
