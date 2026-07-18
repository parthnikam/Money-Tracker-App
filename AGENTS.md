# Agents.md - Personal Finance App

## Read first (agent context docs)

Longer, durable context lives in `docs/`. Prefer these over rediscovering the repo:

| Doc | Purpose |
|-----|---------|
| [docs/projectbrief.md](docs/projectbrief.md) | Scope and goals |
| [docs/productContext.md](docs/productContext.md) | Users, jobs, UX principles |
| [docs/uiRequirements.md](docs/uiRequirements.md) | **UI system requirements** (theme, glass, screens) |
| [docs/systemPatterns.md](docs/systemPatterns.md) | Architecture and patterns |
| [docs/techContext.md](docs/techContext.md) | Stack and constraints |
| [docs/activeContext.md](docs/activeContext.md) | Current focus / working notes |
| [docs/progress.md](docs/progress.md) | Done vs pending log |

Layout inspiration only: `ui_design/` screenshots. **Do not** copy their light palette — follow `docs/uiRequirements.md`.

## Project Overview
A clean, private personal finance tracker. Users can track income, expenses, budgets, and view simple insights. Focus on simplicity, speed, and data privacy (local-first).

## Core Architecture Rules
- **Feature-first** structure
- Clean layers inside each feature: `data` → `domain` → `presentation`
- State management: Riverpod (preferred)
- Navigation: go_router
- UI: Material 3 with custom design system
- All business logic belongs in domain or viewmodels — never in widgets
- Prefer local storage (Isar/Hive) first, optional sync later

## Folder Structure
lib/
├── core/          # theme, utils, config, di, router
├── shared/        # reusable widgets, models, services
├── features/      # auth, transactions, budget, reports, settings
│   └── [feature]/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── app/
└── main.dart


## UI Design
Full requirements: **[docs/uiRequirements.md](docs/uiRequirements.md)**

Summary:
- Glass design cards (inset or outset); no borders; rounded corners
- Single clean sans font; limited font sizes
- Black `#070600`, white `#F7F7FF`, accent `#ea526f` (no purple)
- Smooth screen transitions
- Floating glass bottom navbar
- Use `ui_design/` for layout structure only

## Key Packages
- riverpod + hooks_riverpod
- go_router
- isar (or hive) — currently Hive
- intl
- fl_chart (for simple charts)
- uuid

## Coding Guidelines
- Use freezed for models where complex
- Name files in `snake_case.dart`
- Keep widgets small and dumb
- Add clear comments for complex logic
- Follow existing patterns strictly

## Common Tasks

**Adding a new feature:**
1. Create folder in `features/`
2. Add data → domain → presentation layers
3. Register provider/route in core/app

**Working with transactions:**
- Use Transaction entity (domain)
- Repository pattern for data operations

## AI Collaboration Rules
- Keep changes minimal and focused
- Maintain clean separation of concerns
- Prioritize simplicity and performance
- Always test basic flows after changes
- Update `docs/progress.md` and `docs/activeContext.md` when finishing meaningful work

---
