# System Patterns

## Architecture style
**Feature-first** modular structure with clean layers inside each feature:

```
feature/
  data/          # Hive (or later API) implementations
  domain/        # Entities + repository interfaces
  presentation/  # Screens, feature-only widgets
```

Cross-cutting code lives in:
- `lib/core/` — theme, router, DI providers, storage, utils
- `lib/shared/` — reusable UI widgets
- `lib/app/` — root `MaterialApp.router`

```
lib/
├── core/
│   ├── config/
│   ├── di/
│   ├── router/
│   ├── storage/
│   ├── theme/
│   └── utils/
├── shared/widgets/
├── features/
│   ├── home/presentation/
│   ├── transactions/{data,domain,presentation}/
│   ├── cards/{data,domain,presentation}/
│   ├── budget/{data,domain,presentation}/
│   ├── reports/presentation/
│   └── settings/presentation/
├── app/app.dart
└── main.dart
```

## Layer rules

| Layer | Allowed | Forbidden |
|-------|---------|-----------|
| **Presentation** | Widgets, Riverpod `ref.watch`, navigation, form UI | Hive boxes, business formulas duplicated ad-hoc |
| **Domain** | Entities, repository interfaces, pure helpers | Flutter widgets, Hive |
| **Data** | Implements repositories, map ↔ entity, box access | UI imports |

**All business logic belongs in domain or providers/viewmodels — never in widgets.**

## State management
- **Riverpod** (`flutter_riverpod` / `hooks_riverpod`)
- Repository providers in `lib/core/di/providers.dart`
- StreamProviders for reactive lists from Hive repos
- Derived providers for period filters, totals, category maps
- `StateProvider` for ephemeral UI state (e.g. `reportPeriodProvider`)

Pattern:
```dart
final xRepositoryProvider = Provider<XRepository>(...);
final xListProvider = StreamProvider<List<X>>((ref) => ref.watch(xRepositoryProvider).watchAll());
final derivedProvider = Provider((ref) => ref.watch(xListProvider).whenData(...));
```

## Repository pattern
- Domain defines abstract repositories (`TransactionRepository`, `CategoryRepository`, …)
- Data implements with Hive (`HiveTransactionRepository`, …)
- Broadcast `StreamController` + initial yield for `watchAll()` so UI updates after writes

## Persistence
- **Hive** boxes (string maps), opened in `main.dart` before `runApp`
- Box names in `HiveBoxes`
- Entities serialize via `toMap` / `fromMap` (no Freezed codegen yet)
- **First launch** via `seedIfEmpty()`: default categories + empty primary wallet only (no demo money data)

## Navigation
- **go_router** with `ShellRoute` for bottom-nav tabs
- Root navigator for modal-style full screens (add tx, add card, categories, budgets, savings)
- Paths:
  - `/` Home
  - `/stats` Stats
  - `/cards` Cards
  - `/settings` Settings
  - `/transactions/add`, `/cards/add`, `/categories`, `/budgets`, `/savings/add`
- Custom transitions in `createAppRouter()`

## Domain model sketch

```
WalletCard ──< Transaction >── Category
                  │
                  └── Budget (category + month + limit)

SavingsPlan (standalone goals)
```

- `TransactionType`: `income` | `expense`
- Adding a transaction should adjust the linked card’s balance (current behavior in add flow)

## UI composition patterns
- Shared surface cards and nav in `shared/widgets`
- Screens are mostly `ConsumerWidget` / `ConsumerStatefulWidget`
- Period filtering centralized in providers, not copied per screen

## Adding a new feature (checklist)
1. Create `features/<name>/{data,domain,presentation}/`
2. Define entity + repository interface in domain
3. Implement Hive repository in data
4. Register providers in `core/di/providers.dart`
5. Open box in `main.dart` if new box needed
6. Add routes in `core/router/app_router.dart`
7. Keep widgets dumb; put logic in domain/providers
8. Match [uiRequirements.md](./uiRequirements.md)

## Coding conventions
- Files: `snake_case.dart`
- Prefer small widgets
- Freezed for complex models **when** complexity warrants (not required for simple map-backed entities today)
- Comments only for non-obvious logic
- Minimal diffs; follow existing patterns strictly

## Testing approach (current)
- Lightweight unit placeholder test exists
- Full widget tests need Hive init / ProviderScope
- After changes: run `flutter analyze` and exercise primary flows

## Future architectural options
- Freezed + json/hive adapters for safer models
- Isar if query performance becomes a bottleneck
- Optional sync layer behind the same repository interfaces (domain stays stable)
