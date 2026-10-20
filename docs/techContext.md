# Tech Context

## Platform
- **Flutter** app (mobile-first; also has web/desktop folders from template)
- SDK: Dart **^3.12.2** (project generated with Flutter 3.44.x / Dart 3.12.x)
- Package name: `app_v0` (folder/project name; product name **MoneyTracker**)

## Stack

| Concern | Package / choice | Notes |
|---------|------------------|-------|
| UI framework | Flutter Material 3 | Custom dark theme |
| State | `flutter_riverpod`, `hooks_riverpod`, `flutter_hooks` | Prefer Riverpod |
| Navigation | `go_router` | Shell + root routes |
| Local DB | `hive`, `hive_flutter` | Chosen over Isar for simpler setup |
| IDs | `uuid` | Entity IDs |
| Formatting | `intl` | Currency, dates |
| Charts | `fl_chart` | Sparklines; expand as needed |
| Fonts | `google_fonts` | Inter |
| Paths | `path_provider` | Via Hive init |

### Dev dependencies
- `flutter_lints`
- `hive_generator`, `build_runner` (available; not heavily used yet — maps are hand-written)

## Key paths

| Path | Role |
|------|------|
| `lib/main.dart` | Binding, Hive open, seed, `ProviderScope` |
| `lib/app/app.dart` | `MaterialApp.router` |
| `lib/core/theme/` | `AppColors`, `AppTheme` |
| `lib/core/di/providers.dart` | Repositories + derived finance providers |
| `lib/core/router/app_router.dart` | Routes + `AppShell` |
| `lib/core/storage/` | Box names + seed data |
| `lib/features/*` | Feature modules |
| `lib/shared/widgets/` | Glass UI kit |
| `docs/` | Agent context docs (this set) |
| `ui_design/` | Layout reference screenshots |
| `AGENTS.md` | Short agent rules (root) |

## Runtime constraints
- **Local-first**: no backend required
- Portrait orientation locked
- Hive boxes opened before UI runs
- First-run seed only if categories box is empty (categories + zero-balance wallet; no demo txs)
- Default currency display: USD-style (`$`, 2 decimals) — not a full multi-currency engine yet

## Environment / tooling
```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Constraints for agents
1. Do not introduce a second state-management library (no Bloc/GetX alongside Riverpod without explicit decision).
2. Do not replace Hive mid-flight without migration plan.
3. Prefer existing providers over new global singletons.
4. New dependencies need a clear reason; keep the set lean.
5. Match UI to [uiRequirements.md](./uiRequirements.md) — not to light-mode screenshots literally.
6. Windows host is a common dev environment for this repo; avoid Unix-only shell assumptions when documenting commands (PowerShell-friendly is good).

## Known technical notes
- Dynamic Material icons from stored code points use `iconFromCodePoint` (`lib/core/utils/icon_utils.dart`) to satisfy analyzer rules.
- Cards are a single opaque color (`SurfaceCard`). Do not add a gradient, a blurred shadow, or `BackdropFilter` to them. Live blur and card shadows repaint on every scroll frame and drop mobile FPS. Buttons, the FAB, and the bottom nav keep their own fills and also must not use `BackdropFilter`.
- Card balance updates happen in the add-transaction flow (presentation currently coordinates repo calls). Longer-term, consider a domain use-case so balance rules stay out of widgets.

## Optional future stack
| Idea | When |
|------|------|
| Freezed models | Entities grow unions/copyWith complexity |
| Isar | Heavy queries / relations |
| Auth + sync | Multi-device requested |
| Codegen Hive adapters | Typed boxes preferred over maps |
