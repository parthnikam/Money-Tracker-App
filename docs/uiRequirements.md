# UI Requirements

Authoritative visual system for MoneyTracker. Future agents **must** follow this when adding or changing UI.

Reference layouts: `../ui_design/*.png` (structure only).  
Colors/theme: this document + `lib/core/theme/`.

---

## 1. Theme tokens

| Token | Value | Usage |
|-------|--------|--------|
| **Black** | **`#070600`** | Dark background / light-mode text |
| **White** | **`#F7F7FF`** | Light background / dark-mode text |
| **Primary / accent** | **`#EA526F`** | Accent, selected nav, FAB, key CTAs |
| Primary soft | `#F07189` | Soft accents, selected fills |
| Primary muted | `#C43D58` | Gradients, deeper stops |
| Surface (dark) | `#12110C` | Elevated panels |
| Surface elevated (dark) | `#1A1914` | Sheets, menus |
| Text secondary | muted gray | Subtitles, section labels |
| Income | green family | Positive amounts |
| Expense | red family | Negative amounts |
| Glass fill | white/black low alpha | Small tracks and chips only |
| Nav bar | near-background translucent | Floating bottom bar |

**Rules**
- Supports light and dark mode (see Settings).
- No light-theme reimplementation of reference screenshots as the brand.
- **No purple.** Accent is always `#ea526f` (`AppColors.primary`).

---

## 2. Typography

- **One family**: clean sans — Inter via `google_fonts` (already wired in `AppTheme`).
- **Do not** introduce multiple decorative fonts.
- Keep a small size scale:
  - Body / list titles ~14–15
  - Section headers ~16 (semi-bold)
  - Screen titles ~20–24 (bold)
  - Hero balance ~28–32 (bold)
  - Meta / captions ~11–12
- Prefer `FontWeight.w400`, `w600`, `w700` only.

---

## 3. Surfaces

### Cards (`SurfaceCard`)
- Solid opaque fill: `AppThemeColors.surface` for raised panels
- **No gradient, no shadow, no backdrop blur.** Those repaint on every scroll frame and make lists slow
- **No borders**
- Corner radius: **14–20** default; larger (~24–28) for hero panels / nav
- Depth modes:
  - **Outset** — solid surface (home spending card, settings groups, category and budget rows)
  - **Inset** — one darker solid color for the period control
  - **Flat** — same solid fill

### Do / don’t
| Do | Don’t |
|----|--------|
| Rounded corners everywhere meaningful | Sharp rectangles |
| One solid surface color per card | Card gradients, blurred shadows, or `BackdropFilter` |
| Consistent padding (16–20) | Random paddings per screen |
| Single rose accent `#ea526f` | Purple or multi-brand rainbow |

### Wallet / payment cards
- Full gradient tiles (these are the payment card, not `SurfaceCard`) for card identity
- Show bank name (when set), wallet name, balance, last 4, holder
- Cards are editable and removable from the Cards tab and the edit form
- Soft colored shadow matching gradient

---

## 4. Layout & spacing

- Page horizontal padding: **20** (`AppConstants.pagePadding`)
- Vertical rhythm: 8 / 12 / 16 / 20 / 24
- Lists: plain transaction rows; group settings and similar blocks in `SurfaceCard`
- Grids: 2-column category expense cards on Stats
- Leave bottom clearance for floating nav (**~100–120** content padding)

---

## 5. Navigation

### Floating glass bottom navbar
- Floats above bottom safe area with horizontal inset (~24)
- Pill / stadium shape (large radius ~28)
- Opaque dark floating pill (no live blur — same scroll-cost rule as cards)
- **4 tabs**: Home · Stats · Cards · Settings
- Active: accent icon + label; inactive: tertiary gray
- Smooth highlight on selected item (subtle accent fill)

### Transitions
- Tab changes: **fade + slight horizontal slide** (`CustomTransitionPage`)
- Modal/create routes: **slide up + fade**
- Keep animations short (~200–250ms), `Curves.easeOutCubic`

### FAB
- Primary accent circle (`#ea526f`)
- Shown on Home and Stats → opens **Add transaction**
- Align with Material 3; no dual FABs competing with nav

---

## 6. Screen-specific UI requirements

Tab titles use `headlineSmall`, weight 700.

### Home
- No greeting or avatar. The spending card is the top of the screen
- Hero surface card: “Your spending”, large amount, sparkline/chart, period menu, in/out chips
- Section “Savings plans” with horizontal scrolling solid cards + progress bars
- Section “Recent transactions” with see-more → Stats
- Match **structure** of home reference (balance first, savings, recent)

### Stats
- Title “Your expenses” + period subtitle
- Centered period selector (Week / Month / Year compact; full periods available elsewhere)
- Large **arc / semi-ring** expense visualization with total in center
- Category spend list (dot color + name + amount). Tapping a category, a dial slice, or a list heading highlights that category on the dial, the legend, and the heading. Tap it again to clear.
- “Latest transactions” list
- Match **structure** of expenses/stats reference

### Cards / Wallet details
- Screen title “Wallet details”
- Large gradient card widget
- Horizontal wallet switcher chips
- Solid search field
- Filtered transaction list for active card
- Match **structure** of wallet-details reference

### Settings
- Grouped solid lists (not dense Material menus)
- Icon-in-rounded-square leading, chevron trailing
- Keep calm and sparse

### Forms (add tx / card / etc.)
- Same input theme: filled fields, no harsh borders until focus
- Focus border may use primary accent stroke
- Primary CTA: full-width `FilledButton`, height ~52, radius 16
- Type toggles (expense/income) as a segmented control

---

## 7. Components (reuse these)

| Widget | Path | Role |
|--------|------|------|
| `SurfaceCard` | `shared/widgets/surface_card.dart` | Solid panels |
| `GlassBottomNav` | `shared/widgets/glass_bottom_nav.dart` | Shell nav |
| `PeriodSelector` | `shared/widgets/period_selector.dart` | Report range chips |
| `TransactionTile` | `shared/widgets/transaction_tile.dart` | Tx row |
| `WalletCardWidget` | `shared/widgets/wallet_card_widget.dart` | Payment card visual |
| `SectionHeader` | `shared/widgets/section_header.dart` | Title + action |

**Rule:** Prefer extending these over inventing new card styles.

---

## 8. Charts & data viz

- Use `fl_chart` for line/sparkline and future bars
- Custom painters OK for simple arcs (Stats expense ring)
- Chart colors: rose accent family + category colors
- Tooltips: elevated surface, short currency strings
- No gridlines unless they aid reading

---

## 9. Iconography & imagery

- Material Icons only (unless product decides otherwise)
- Soft tinted icon wells (accent or category color at ~18% alpha)
- Avoid photographic backgrounds; keep UI graphic and clean

---

## 10. States

| State | Treatment |
|-------|-----------|
| Loading | Small centered `CircularProgressIndicator` or skeleton-free shrink space |
| Empty | Surface card + short copy + primary action when possible |
| Error | Simple text; SnackBar for transient failures |
| Success | Pop route / list update via streams (no heavy celebration) |

---

## 11. Platform polish

- Portrait preferred (already locked in `main.dart`)
- Status bar: light icons on dark background
- System nav bar color matches background
- Safe areas respected; bottom nav sits in safe area

---

## 12. Explicit anti-patterns

- ❌ Light mint backgrounds from screenshots as production theme  
- ❌ Borders, gradients, or shadows on surface cards  
- ❌ Many font families or heading sizes  
- ❌ Business logic inside widgets  
- ❌ One-off colors outside `AppColors` without reason  
- ❌ Dense banking-app tables without grouped surface cards  

---

## Checklist for new UI work

- [ ] Uses `AppColors` / `AppTheme`
- [ ] Solid `SurfaceCard` panels; no borders, gradients, or shadows
- [ ] Rounded corners consistent with constants
- [ ] Bottom content not hidden by floating nav
- [ ] Text hierarchy uses standard sizes
- [ ] Primary actions use `#EA526F`
- [ ] Signed money uses income/expense colors
- [ ] Transitions match existing router patterns
