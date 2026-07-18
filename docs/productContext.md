# Product Context

## Who is this for?
Primary user: **an individual** who wants a private, low-friction way to see where money goes.

Assumptions:
- Uses one device primarily
- Cares about privacy (local data preferred)
- Wants clarity over spreadsheets or heavy banking apps
- Comfortable with simple category-based tracking

## Problems we solve
| Problem | Product response |
|---------|------------------|
| “I don’t know where my money went this month” | Period filters + category expense breakdown |
| “Budgeting apps feel heavy / nosy” | Local-first, minimal UI, no forced accounts |
| “I spend from multiple cards/wallets” | Card/wallet entities linked to transactions |
| “I forget savings goals” | Savings plans with progress bars |
| “Adding expenses is tedious” | Fast add flow + FAB on Home/Stats |

## Core user jobs
1. **Log money** — record expense or income with amount, category, card, date
2. **Review** — glance at balance, recent activity, period spend
3. **Control** — set category budgets; watch overspend
4. **Plan** — create savings targets and track progress
5. **Organize** — create categories and wallets

## Primary screens (mental model)

### Home
- Greeting / wallet welcome
- Total balance across wallets
- Lightweight chart of recent movement
- Income vs expense summary for selected period
- Horizontal savings plans
- Recent transactions

### Stats / Reports
- Period chips: Week · Month · Year (and deeper filters: 3M, 6M, All)
- Total expenses visualization (arc / chart)
- Category spend cards grid
- Latest expense list (swipe to delete where supported)

### Cards / Wallet details
- Visual card (gradient) with balance & last four
- Switch between wallets
- Search transactions for selected card
- Transaction list for that card

### Settings
- Entry point for categories, budgets, savings, add card/tx
- About / local-first messaging

### Secondary flows
- Add transaction (expense | income)
- Add card/wallet
- Categories CRUD
- Budgets set/view
- Add savings plan

## UX principles
1. **Minimal** — few fonts, few sizes, little chrome
2. **Glanceable** — big balance numbers, clear signed amounts
3. **Fast entry** — defaults for category/card; short forms
4. **Private by default** — no network required for core use
5. **Honest feedback** — income green, expense red/soft coral; budget over = clear warning
6. **Motion with purpose** — smooth tab transitions; modal-style sheets for creates

## Content & tone
- Short labels (“Your balance”, “Latest transactions”)
- Currency formatted with `$` and two decimals (current default: USD-style)
- Empty states explain the next action (“No cards yet” → Add card)

## Accessibility (baseline)
- Contrast: white/secondary gray text on near-black
- Touch targets comfortable on bottom nav and FAB
- Prefer Material icons + text labels on nav

## What reference UI means
Screenshots in `ui_design/` show **layout patterns** (hero balance, arc chart, savings cards, wallet detail, floating nav).  
**Do not** copy the light mint/green palette. Map layouts onto black `#070600` / white `#F7F7FF` / accent `#ea526f` (see [uiRequirements.md](./uiRequirements.md)).
