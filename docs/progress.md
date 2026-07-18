# Progress Log

## Status summary
| Area | State |
|------|--------|
| Project scaffold | ✅ Done |
| Theme + glass design system | ✅ Done |
| Routing + shell nav | ✅ Done |
| Hive storage + seed | ✅ Done |
| Domain models + repos | ✅ Done |
| Home screen | ✅ Done (MVP) |
| Stats / reports | ✅ Done (MVP) |
| Cards / wallets | ✅ Done (MVP) |
| Settings hub | ✅ Done (MVP) |
| Add transaction | ✅ Done |
| Add card | ✅ Done |
| Categories CRUD | ✅ Partial (add + delete non-default) |
| Budgets | ✅ Partial (list + add) |
| Savings plans | ✅ Partial (list on Home + add) |
| Auth / sync | ❌ Not started (out of scope for now) |
| Agent docs | ✅ This docs set |
| Full test suite | ❌ Minimal placeholder only |

---

## Done (changelog)

### 2026-07-17 — Initial app foundation
- Replaced Flutter counter template with MoneyTracker app shell
- Added dependencies: Riverpod, go_router, Hive, intl, fl_chart, uuid, google_fonts
- Implemented `AppColors` / `AppTheme` (black + `#9D4EDD` + Inter)
- Built shared glass widgets and floating bottom nav
- Domain + Hive repos: transactions, categories, cards, budgets, savings
- Seed data for first launch
- Screens: Home, Stats, Cards, Settings
- Flows: add transaction (updates balance), add card, categories sheet, budgets sheet, add savings
- Period filtering providers (week → all time)
- Stats arc chart + category grid; Home sparkline
- `flutter analyze` clean; basic test passes
- README updated

### 2026-07-17 — Agent documentation set
- Added `docs/projectbrief.md`
- Added `docs/productContext.md`
- Added `docs/uiRequirements.md` (full UI system)
- Added `docs/systemPatterns.md`
- Added `docs/techContext.md`
- Added `docs/activeContext.md`
- Added `docs/progress.md` (this file)

### 2026-07-17 — Branded splash + app name
- Product display name set to **Personal Finance** (`AppConstants.appName`)
- **Single native launch splash only** (no Flutter overlay screen): logo + title baked into Android/iOS launch assets
- Labels/icons: Android, Windows, iOS, macOS, web
- Init still runs before `runApp`; first Flutter frame is the real app

### 2026-07-17 — CSV import (append)
- `TransactionCsvImport` parses export-format CSV (BOM, quoted fields, flexible headers)
- Settings → **Import transactions (CSV)** via `file_selector`; appends only (skips existing ids)
- Updates wallet balances for imported income/expense
- Unit tests in `test/transaction_csv_import_test.dart`
- Dependency: `file_selector`

### 2026-07-17 — Empty first launch
- Removed demo transactions, budgets, savings, and second wallet from seed
- First open: default categories + one Main Wallet at ₹0 only

---

## Pending

### Product / UX
- [ ] Edit existing transaction (and reverse/adjust card balance correctly)
- [ ] Delete transaction from more entry points (with balance correction)
- [ ] Edit/delete cards and savings plans
- [ ] Budget progress widgets on Home
- [ ] Richer empty states and first-run without only demo seed (optional onboarding)
- [ ] Pull category filters / search on Stats
- [ ] Accessibility pass (semantics, larger text)

### Technical
- [ ] Domain use-cases for “record transaction” (balance + write atomic)
- [ ] Freezed (or equivalent) for complex entities
- [ ] Hive type adapters or stronger typing
- [ ] Widget/integration tests with Hive in-memory
- [ ] CI analyze + test
- [x] App display name / launcher branding beyond default `app_v0` (Personal Finance + logo splash)

### Explicitly later
- [ ] Cloud sync
- [ ] Bank linking
- [ ] Multi-currency engine
- [ ] Auth

---

## How to update this file
When finishing work, append a dated “Done” bullet and move checklist items from Pending → Done. Keep summaries short so agents can scan in seconds.
