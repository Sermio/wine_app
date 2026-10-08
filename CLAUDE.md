# CLAUDE.md

Cata (`wine_app`): Flutter + Firebase app for blind wine tastings. Organisers create tastings with wines (alias, description, price, photo); participants rank them blind; closed tastings show aggregated results. See `README.md`.

## Layout
- `lib/main.dart` — Firebase init, Material 3 theme, auth gate (login vs home).
- `lib/models/` — `Cata`, `ElementoCata`, `Voto` (supports new ranking `posicion` and legacy `puntuacion` 1–10).
- `lib/services/` — `AuthService` and `FirestoreService` (`ChangeNotifier`, provided via `provider`). All Firestore/Storage access goes here.
- `lib/screens/` — one file per screen (login, home, create_cata, votacion_detail, vote_form, resultados, resultados_detail).
- `lib/utils/styles.dart` — colours, spacing, radii and text styles. Use these tokens instead of literals.
- Firestore: `catas/{id}/elementos/{id}/votos/{uid}`, `usuarios/{uid}.nombre`. Rules in `firestore.rules`, `storage.rules`.

## Commands
- `flutter pub get`, `flutter analyze`, `flutter test`
- `flutter run -d chrome` for web; deploy with `deploy_firebase.bat` / `.sh` (see `DEPLOY_WEB.md`).
- Versions: see `pubspec.yaml` and `flutter --version`.

## Conventions
- UI text is in Spanish; keep new strings consistent.
- Lints: `flutter_lints` via `analysis_options.yaml`.
- Results ranking = sum of positions, lower is better; unvoted wines must not break sorting.

## Modularity and reuse
- Search `lib/` for an existing widget, style token or service method before creating one.
- Extract any UI or logic used twice into a shared widget/helper (e.g. a `lib/widgets/` folder).
- Keep files focused; screens like `create_cata.dart` are already large — split new pieces out.
- Keep business and Firestore logic in `services/`, not in widgets.
