# Active Context

> Update this file when starting a new task or finishing a meaningful chunk of work.

## Current focus
Cards can be edited, given a bank name, and removed. Panels are solid `SurfaceCard`s (no gradient, shadow, or blur) so lists stay smooth while scrolling. Tab shell uses `PageView` for swipe between Home / Stats / Cards / Settings.

## Recent decisions
- **Hive** (not Isar) for v0 local storage — simpler setup, map-backed entities.
- **Theme** black `#070600`, white `#F7F7FF`, accent `#ea526f` — no purple.
- **No Freezed yet** — plain immutable classes + `toMap`/`fromMap`.
- **go_router ShellRoute** for 4-tab glass bottom nav; modal routes on root navigator.
- First-run is **empty**: default category catalog + one zero-balance wallet only; no demo transactions/budgets/savings.

## Working notes for agents
1. Always read `AGENTS.md` + `docs/uiRequirements.md` before UI changes.
2. Business logic stays out of widgets; use domain + Riverpod providers.
3. When adding screens, reuse `SurfaceCard`, `GlassBottomNav`, `TransactionTile`, etc.
4. Period filtering already lives in `reportPeriodProvider` / `filteredTransactionsProvider` — extend those rather than re-filtering ad hoc.
5. After code changes: `flutter analyze` (must be clean) and smoke-test Home → Add tx → Stats.
6. Do not put gradients, blurred shadows, or `BackdropFilter` back on cards. Buttons and the nav may keep their existing fills.

## Open questions / product choices (not blocked)
- Multi-currency vs single default currency
- Whether to show onboarding vs seed demo forever
- Auth / sync timeline
- Whether budgets are calendar-month only or rolling windows
- User-editable display name on Home (currently generic “Your wallet”)

## Next recommended engineering tasks
See [progress.md](./progress.md) “Pending”.

Highest leverage next steps:
1. Edit / delete transaction (full flow, balance correction)
2. Surface budgets on Home/Stats
3. Stronger empty states + pull-to-refresh optional
4. Widget tests with Hive test harness
5. Freezed for `Transaction` if mutation surface grows

## Do not regress
- Floating glass bottom nav + dark theme tokens
- Feature-first folders
- Local-first empty first launch (no demo money data)
- Balance adjustment when adding income/expense
