# Project Brief — MoneyTracker

## One-liner
A clean, private, local-first personal finance tracker for everyday money management.

## Goals
1. Let users **track income and expenses** quickly, by category.
2. Let users **set spending budgets** and see progress without complexity.
3. Let users **manage wallets/cards** as sources of spend.
4. Surface **simple insights** (period totals, category breakdowns, savings goals).
5. Prioritize **simplicity, speed, and data privacy** over feature bloat.

## In scope (product)
- Expense and income transactions
- Custom categories
- Spending budgets (monthly, per category)
- Savings plans / goals
- Cards / wallets as spend sources
- Reports for: week, month, 3 months, 6 months, year, all time
- Minimal glass-style UI (dark theme)
- Local-first persistence (no account required for core use)

## Out of scope (for now)
- Cloud sync / multi-device (optional later)
- Bank / Plaid integrations
- Multi-currency conversion engines
- Investments portfolio management
- Tax filing / invoicing
- Social / shared household accounts
- Authentication-heavy multi-user backend

## Success criteria
- Core flows work offline after first install
- Adding a transaction takes few taps
- UI matches design system (black / white / rose accent glass)
- Architecture stays feature-first and agent-friendly
- Data remains on device by default

## Non-goals
- Replicating every feature of Mint/YNAB/Monarch
- Perfect financial advice / AI coaching (unless explicitly requested later)
- Pixel-perfect clone of light-mode reference shots — **adapt layout ideas to our dark glass system**

## Related docs
| Doc | Purpose |
|-----|---------|
| [productContext.md](./productContext.md) | Users, problems, UX principles |
| [uiRequirements.md](./uiRequirements.md) | Visual / UI system requirements |
| [systemPatterns.md](./systemPatterns.md) | Architecture & patterns |
| [techContext.md](./techContext.md) | Stack & constraints |
| [activeContext.md](./activeContext.md) | Current focus |
| [progress.md](./progress.md) | Done / pending log |
| [../AGENTS.md](../AGENTS.md) | Short agent operating rules |
| [../ui_design/](../ui_design/) | Reference screenshots (layout inspiration) |
