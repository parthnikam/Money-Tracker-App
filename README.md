# MoneyTracker

A clean, private, local-first personal finance app built with Flutter.

## Features

- **Track expenses & income** by category
- **Custom categories** with icons and colors
- **Monthly budgets** with spend progress
- **Cards / wallets** as spend sources
- **Savings plans** with targets
- **Reports** for week, month, 3M, 6M, year, and all time
- **Glass UI** — black `#070600`, white `#F7F7FF`, accent `#ea526f`

## Stack

| Layer | Choice |
|-------|--------|
| State | Riverpod |
| Navigation | go_router |
| Storage | Hive (local) |
| Charts | fl_chart |
| UI | Material 3 + solid surface cards |

## Architecture

Feature-first structure with `data` → `domain` → `presentation` layers:

```
lib/
├── core/          # theme, router, storage, di, utils
├── shared/        # glass widgets, shared UI
├── features/      # home, transactions, cards, budget, reports, settings
├── app/
└── main.dart
```

## Run

```bash
flutter pub get
flutter run
```

First launch starts empty: default categories and one zero-balance wallet only — no demo transactions, budgets, or savings.

## Design

- Black `#070600`, white `#F7F7FF`, accent `#ea526f`
- Solid surface cards (inset / outset), no borders
- Floating glass bottom navigation
- Smooth fade/slide transitions
- Reference screenshots in `ui_design/`
- Full UI rules: [docs/uiRequirements.md](docs/uiRequirements.md)

## Agent / project docs

| File | Purpose |
|------|---------|
| [docs/projectbrief.md](docs/projectbrief.md) | Scope and goals |
| [docs/productContext.md](docs/productContext.md) | UX and users |
| [docs/uiRequirements.md](docs/uiRequirements.md) | UI system |
| [docs/systemPatterns.md](docs/systemPatterns.md) | Architecture |
| [docs/techContext.md](docs/techContext.md) | Stack |
| [docs/activeContext.md](docs/activeContext.md) | Current focus |
| [docs/progress.md](docs/progress.md) | Done / pending |
| [AGENTS.md](AGENTS.md) | Short agent rules |
