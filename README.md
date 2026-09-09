# MovieRadar

A simple, offline-first movie watchlist app built with **Flutter**. Keep track of what you want to watch, what you've already seen, and let MovieRadar pick your next film when you can't decide.

## Features

- **Watchlist & Watched tabs** — Your to-watch list and your history at a glance.
- **Random movie picker** — Stuck deciding what to watch? MovieRadar shuffles through your unwatched movies with an animated slot-machine style reveal and can take you straight to the details.
- **Add movies from TMDB** — Search the [TMDB](https://www.themoviedb.org/) catalog with live, debounced search results and auto-fill title, director, year, overview, and poster. You can also add or edit movies manually.
- **Movie details** — Poster, director, release year, overview, date added, and date watched. Toggle watch status or delete a movie from its detail screen.
- **Search** — Instantly filter your collection by title.
- **List & grid views** — Switch between a detailed list and a poster grid; your preference is remembered.
- **Light / dark / system theme** — Material 3 theming with an indigo seed color.
- **Import & export** — Back up your collection or move it between devices by exporting JSON files (save to a location, share them, or store them in the MovieRadar folder). Import with either **Replace All** or **Merge** to avoid duplicates.
- **Local storage only** — Your collection is stored on-device with `SharedPreferences`. No accounts, no cloud, no tracking.

## Download

Get the latest `movieradar.apk` from the [Releases](https://github.com/HyperDarkmoon/movieradar/releases) page. It's a self-signed APK, so allow installation from unknown sources and install it directly.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable)
- Android SDK (for building the APK)

### Running in development

```sh
flutter pub get
flutter run
```

### TMDB API key

Adding movies by search uses the TMDB API. The key is configured in `lib/services/tmdb_service.dart`:

```dart
static const String apiKey = 'YOUR_TMDB_API_KEY';
```

Register a free key at [themoviedb.org](https://www.themoviedb.org/) and replace it if you plan to ship your own build.

## Building the release APK

```sh
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Android release signing

To install as an update (instead of uninstalling), the APK must be signed with the same keystore as the currently installed app.

1. Copy `android/key.properties.example` to `android/key.properties`.
2. Fill in the keystore values in `android/key.properties`.
3. Build with `flutter build apk --release`.

If `android/key.properties` is missing, release builds fall back to debug signing.

**Never commit `android/key.properties` or your keystore file** — both are gitignored. Keep them safe; if you lose them, you can't sign updates for an already-installed app.

## Project structure

```
lib/
├── main.dart                      # App entry point and theme setup
├── models/
│   ├── movie.dart                 # Movie data model
│   └── import_result.dart         # Import operation result
├── providers/
│   └── theme_provider.dart        # Theme (system/light/dark) state
├── screens/
│   ├── main_screen.dart           # Watchlist/Watched tabs, search, list/grid, random picker
│   ├── add_movie_screen.dart      # TMDB search + manual movie entry
│   ├── movie_detail_screen.dart   # Movie details, watch toggle, delete
│   ├── settings_screen.dart       # Appearance & data management
│   └── import_export_screen.dart  # JSON backup/restore
└── services/
    ├── movie_service.dart         # Local persistence via SharedPreferences
    └── tmdb_service.dart          # TMDB search + details API
```

## Tech stack

- **Flutter / Dart** — Material 3 UI
- **Provider** — state management
- **shared_preferences** — local persistence
- **cached_network_image** — poster caching
- **http** — TMDB API calls
- **file_picker / file_selector** — export/import file access
- **share_plus** — sharing export files
- **path_provider / permission_handler** — storage access