"""
Merge old_budget.csv + older_expenses.csv into app export format.

Output schema (matches TransactionCsvExport.csvHeader):
  id, date, type, title, amount, category, category_id,
  account, account_id, payment_method, notes

Dedup rule: same calendar day + same amount (+ same type) = one transaction.
Richer fields win; REVELS-style daily aggregates are dropped when detail exists.
"""

from __future__ import annotations

import csv
import re
import uuid
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent
OLD_BUDGET = DATA_DIR / "old_budget.csv"
OLDER_EXPENSES = DATA_DIR / "older_expenses.csv"
OUTPUT = DATA_DIR / "merged_transactions.csv"

HEADER = [
    "id",
    "date",
    "type",
    "title",
    "amount",
    "category",
    "category_id",
    "account",
    "account_id",
    "payment_method",
    "notes",
]

# Map source category labels -> (app category name, category_id)
CATEGORY_MAP = {
    # older_expenses
    "PERSONAL CARE": ("Personal Care", "cat_personal"),
    "FOOD / SNACKS": ("Food", "cat_food"),
    "ACADEMIC STATIONARY": ("Education", "cat_education"),
    "TRAVEL": ("Transportation", "cat_transport"),
    "ACCESSORIES": ("Shopping", "cat_shopping"),
    "EVENTS": ("Social", "cat_social"),
    "MISC": ("Shopping", "cat_shopping"),
    "DIGITAL SUBSCRIPTIONS": ("Subscriptions", "cat_subs"),
    # old_budget
    "Food": ("Food", "cat_food"),
    "Transportation": ("Transportation", "cat_transport"),
    "Personal Care": ("Personal Care", "cat_personal"),
    "Education": ("Education", "cat_education"),
    "Subscriptions": ("Subscriptions", "cat_subs"),
    "Social": ("Social", "cat_social"),
    "Bills": ("Bills", "cat_bills"),
    "Entertainment": ("Entertainment", "cat_ent"),
    "Grants": ("Salary", "cat_salary"),
    "Shopping": ("Shopping", "cat_shopping"),
    "Home": ("Home", "cat_home"),
}


def escape_csv_field(value: str) -> str:
    s = "" if value is None else str(value)
    if any(c in s for c in ',\n\r"'):
        return '"' + s.replace('"', '""') + '"'
    return s


def map_category(raw: str) -> tuple[str, str]:
    raw = (raw or "").strip()
    if not raw:
        return ("", "")
    if raw in CATEGORY_MAP:
        return CATEGORY_MAP[raw]
    for key, value in CATEGORY_MAP.items():
        if key.lower() == raw.lower():
            return value
    upper = raw.upper()
    if "FOOD" in upper or "SNACK" in upper:
        return ("Food", "cat_food")
    if "TRAVEL" in upper or "TRANSPORT" in upper:
        return ("Transportation", "cat_transport")
    if "PERSONAL" in upper or "CARE" in upper:
        return ("Personal Care", "cat_personal")
    if "ACADEMIC" in upper or "EDUCATION" in upper or "STATION" in upper:
        return ("Education", "cat_education")
    if "SUBSCRIP" in upper or "DIGITAL" in upper:
        return ("Subscriptions", "cat_subs")
    if "ENTERTAIN" in upper:
        return ("Entertainment", "cat_ent")
    if "BILL" in upper:
        return ("Bills", "cat_bills")
    if "SOCIAL" in upper or "EVENT" in upper:
        return ("Social", "cat_social")
    if "SHOP" in upper or "ACCESSOR" in upper or "MISC" in upper:
        return ("Shopping", "cat_shopping")
    if "HOME" in upper:
        return ("Home", "cat_home")
    if "GRANT" in upper or "SALARY" in upper:
        return ("Salary", "cat_salary")
    return (raw.title(), "")


def infer_category_from_title(title: str) -> tuple[str, str]:
    low = (title or "").lower()
    if any(
        w in low
        for w in (
            "food",
            "snack",
            "breakfast",
            "lunch",
            "dinner",
            "cake",
            "biscuit",
            "cookie",
            "lassi",
            "burger",
            "icecream",
            "ice cream",
        )
    ):
        return ("Food", "cat_food")
    if any(
        w in low
        for w in ("transport", "auto", "uber", "metro", "bus", "cab", "flight", "plane")
    ):
        return ("Transportation", "cat_transport")
    if "print" in low or "notebook" in low or "lab" in low or "pen" in low:
        return ("Education", "cat_education")
    if "subscription" in low or "toastmasters sub" in low:
        return ("Subscriptions", "cat_subs")
    if "hackathon" in low or "toastmaster" in low or "revels" in low:
        return ("Social", "cat_social")
    if "summer" in low or "intern" in low or "certif" in low:
        return ("Education", "cat_education")
    if "gym" in low or "haircut" in low or "soap" in low or "toothpaste" in low:
        return ("Personal Care", "cat_personal")
    return ("Shopping", "cat_shopping")


def parse_old_time(s: str) -> datetime:
    s = s.strip().strip('"')
    for fmt in ("%b %d, %Y %I:%M %p", "%b %d, %Y %H:%M"):
        try:
            return datetime.strptime(s, fmt)
        except ValueError:
            continue
    raise ValueError(f"Unparsed old_budget TIME: {s!r}")


def parse_older_date(date_s: str, time_s: str) -> datetime | None:
    date_s = (date_s or "").strip().strip('"')
    time_s = (time_s or "").strip().strip('"')
    if not date_s:
        return None
    date_s = re.sub(
        r",\s*(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\s*$",
        "",
        date_s,
        flags=re.I,
    )
    date_s = date_s.replace("Decemeber", "December")
    date_s = re.sub(r"\s+", " ", date_s).strip()
    dt: datetime | None = None
    for fmt in ("%d %B %Y", "%d %b %Y", "%d/%m/%Y", "%m/%d/%Y", "%Y-%m-%d"):
        try:
            dt = datetime.strptime(date_s, fmt)
            break
        except ValueError:
            continue
    if dt is None:
        print(f"WARN unparsed date: {date_s!r}")
        return None
    if time_s:
        for tfmt in ("%I:%M %p", "%H:%M", "%I:%M%p"):
            try:
                t = datetime.strptime(time_s, tfmt)
                dt = dt.replace(hour=t.hour, minute=t.minute)
                break
            except ValueError:
                continue
    return dt


def is_skip_older_row(item: str, amount_s: str) -> bool:
    item = (item or "").strip()
    if not item:
        return True
    if re.search(r"Total\s*:", item, re.I):
        return True
    if re.match(r"REVELS EXPENSES", item, re.I):
        return True
    if re.match(r"REVELS REIMBURSEMENT", item, re.I):
        return True
    if amount_s is None or str(amount_s).strip() == "":
        return True
    return False


def is_revels_aggregate(item: str, merchant: str, desc: str) -> bool:
    """Vague daily rollups under REVELS (Food/Transportation totals)."""
    low = item.strip().lower()
    if merchant.strip() or desc.strip():
        return False
    return low in {
        "food",
        "transportation",
        "food + accomodation",
        "food + accommodation",
    }


def title_from_notes(notes: str, fallback: str) -> str:
    notes = (notes or "").strip()
    if not notes:
        return fallback
    return notes[0].upper() + notes[1:] if len(notes) > 1 else notes.upper()


def load_old_budget() -> list[dict]:
    records: list[dict] = []
    with OLD_BUDGET.open(encoding="utf-8-sig", newline="") as f:
        reader = csv.reader(f)
        headers = [h.strip().strip('"') for h in next(reader)]
        for row in reader:
            if not row or all(not c.strip() for c in row):
                continue
            while len(row) < len(headers):
                row.append("")
            raw = {
                headers[i].strip(): row[i].strip().strip('"')
                for i in range(len(headers))
            }

            def get(key: str) -> str:
                for hk, hv in raw.items():
                    if hk.strip() == key:
                        return hv
                return ""

            time_s = get("TIME")
            type_s = get("TYPE")
            amount_s = get("AMOUNT")
            cat_s = get("CATEGORY")
            acct_s = get("ACCOUNT")
            notes_s = get("NOTES")
            dt = parse_old_time(time_s)
            amount = float(amount_s)
            is_income = "Income" in type_s or "(+)" in type_s
            cat_name, cat_id = map_category(cat_s)
            title = title_from_notes(notes_s, cat_name or "Transaction")
            payment = acct_s if acct_s else "Card"
            records.append(
                {
                    "source": "old_budget",
                    "date": dt,
                    "type": "income" if is_income else "expense",
                    "title": title,
                    "amount": amount,
                    "category": cat_name,
                    "category_id": cat_id,
                    "account": "Main Wallet",
                    "account_id": "card_main",
                    "payment_method": payment,
                    "notes": notes_s,
                    "merchant": "",
                    "richness": 1 + (2 if notes_s else 0) + (1 if cat_name else 0),
                    "is_aggregate": False,
                }
            )
    return records


def load_older_expenses() -> tuple[list[dict], list[str]]:
    """
    Undated rows in older_expenses sit between 6 Oct and 8 Oct 2025
    (Manipal hackathon trip cluster). Assign sequential times on 2025-10-07
    so they are kept rather than dropped.
    """
    records: list[dict] = []
    undated_assigned: list[str] = []
    undated_seq = 0
    # Default day for the undated Manipal-trip cluster
    undated_base = datetime(2025, 10, 7, 12, 0)

    with OLDER_EXPENSES.open(encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            item = (row.get("Item") or "").strip()
            cat_s = (row.get("Category") or "").strip()
            amount_s = (row.get("Amount") or "").strip()
            merchant = (row.get("Merchant") or "").strip()
            date_s = (row.get("Date/Day") or "").strip()
            time_s = (row.get("Time") or "").strip()
            desc = (row.get("Description") or "").strip()
            if is_skip_older_row(item, amount_s):
                continue
            try:
                amount = float(amount_s)
            except ValueError:
                print(f"skip bad amount: {item!r} {amount_s!r}")
                continue
            dt = parse_older_date(date_s, time_s)
            date_inferred = False
            if dt is None:
                # Place undated trip rows on 2025-10-07 with unique minutes
                dt = undated_base.replace(minute=undated_seq)
                undated_seq += 1
                date_inferred = True
                undated_assigned.append(f"{item!r} amount={amount_s} -> {dt}")
            cat_name, cat_id = map_category(cat_s)
            if not cat_name:
                cat_name, cat_id = infer_category_from_title(item)
            notes_parts: list[str] = []
            if merchant:
                notes_parts.append(f"Merchant: {merchant}")
            if desc:
                notes_parts.append(desc)
            if date_inferred:
                notes_parts.append("Date inferred: 2025-10-07 (undated source row)")
            notes = " | ".join(notes_parts)
            aggregate = is_revels_aggregate(item, merchant, desc)
            records.append(
                {
                    "source": "older_expenses",
                    "date": dt,
                    "type": "expense",
                    "title": item,
                    "amount": amount,
                    "category": cat_name,
                    "category_id": cat_id,
                    "account": "Main Wallet",
                    "account_id": "card_main",
                    "payment_method": "Card",
                    "notes": notes,
                    "merchant": merchant,
                    "richness": (
                        2
                        + (2 if merchant else 0)
                        + (2 if desc else 0)
                        + (1 if cat_s else 0)
                        + (0 if aggregate else 3)
                    ),
                    "is_aggregate": aggregate,
                }
            )
    return records, undated_assigned


def drop_covered_aggregates(records: list[dict]) -> list[dict]:
    by_day: dict = defaultdict(list)
    for i, rec in enumerate(records):
        by_day[rec["date"].date()].append(i)

    to_drop: set[int] = set()
    for _day, idxs in by_day.items():
        aggregates = [i for i in idxs if records[i].get("is_aggregate")]
        if not aggregates:
            continue
        detail = [i for i in idxs if not records[i].get("is_aggregate")]
        if not detail:
            continue
        detail_sum = sum(
            records[i]["amount"] for i in detail if records[i]["type"] == "expense"
        )
        agg_sum = sum(records[i]["amount"] for i in aggregates)
        if detail_sum >= agg_sum * 0.85:
            for i in aggregates:
                to_drop.add(i)
                r = records[i]
                print(
                    f"drop aggregate: {r['date'].date()} {r['title']!r} "
                    f"{r['amount']} (day detail sum={detail_sum:.2f})"
                )
    return [r for i, r in enumerate(records) if i not in to_drop]


def merge_group(group: list[dict]) -> dict:
    """Pick richest record; fill missing fields from the rest."""
    group_sorted = sorted(
        group,
        key=lambda r: (
            -r["richness"],
            0 if r["source"] == "older_expenses" else 1,
            -len(r.get("title") or ""),
        ),
    )
    best = dict(group_sorted[0])
    for other in group_sorted[1:]:
        if not best.get("notes") and other.get("notes"):
            best["notes"] = other["notes"]
        elif other.get("merchant"):
            notes = best.get("notes") or ""
            if other["merchant"] not in notes:
                extra = f"Merchant: {other['merchant']}"
                best["notes"] = f"{notes} | {extra}" if notes else extra
        if not best.get("category") and other.get("category"):
            best["category"] = other["category"]
            best["category_id"] = other["category_id"]
        # Prefer a proper item name from older_expenses over a short note title
        other_title = other.get("title") or ""
        best_title = best.get("title") or ""
        if (
            other.get("source") == "older_expenses"
            and not other.get("is_aggregate")
            and len(other_title) > len(best_title)
        ):
            best["title"] = other_title
        # Prefer a non-midnight time if best is midnight-only
        if (
            best["date"].hour == 0
            and best["date"].minute == 0
            and (other["date"].hour or other["date"].minute)
        ):
            best["date"] = other["date"]
    best["sources"] = ",".join(sorted({g["source"] for g in group}))
    best["source"] = best["sources"]  # mark as multi-source for later passes
    return best


def dedupe(records: list[dict]) -> tuple[list[dict], int]:
    """
    Cross-source only: same calendar day + amount + type appearing in BOTH
    files is treated as one transaction (time may differ by a few minutes).

    Same-source collisions (e.g. soap 40 + snacks 40 on the same day) are kept
    as separate rows.
    """
    by_key: dict[tuple, list[dict]] = defaultdict(list)
    for rec in records:
        key = (rec["date"].date().isoformat(), round(rec["amount"], 2), rec["type"])
        by_key[key].append(rec)

    merged: list[dict] = []
    dup_groups = 0
    for group in by_key.values():
        sources = {r["source"] for r in group}
        if len(sources) < 2:
            # Only one source contributed — keep every row (true distinct spends)
            merged.extend(group)
            continue
        # Pair cross-source duplicates by best title/category similarity
        olds = [r for r in group if r["source"] == "old_budget"]
        olders = [r for r in group if r["source"] == "older_expenses"]
        used_older: set[int] = set()
        for o in olds:
            best_j = None
            best_score = -1
            for j, e in enumerate(olders):
                if j in used_older:
                    continue
                score = 0
                if o.get("category") and o.get("category") == e.get("category"):
                    score += 3
                # loose text overlap between notes/title
                ot = f"{o.get('title','')} {o.get('notes','')}".lower()
                et = f"{e.get('title','')} {e.get('notes','')}".lower()
                o_tokens = {t for t in re.split(r"\W+", ot) if len(t) > 2}
                e_tokens = {t for t in re.split(r"\W+", et) if len(t) > 2}
                if o_tokens and e_tokens:
                    score += len(o_tokens & e_tokens)
                # prefer closer times
                score -= abs((o["date"] - e["date"]).total_seconds()) / 86400.0
                if score > best_score:
                    best_score = score
                    best_j = j
            if best_j is not None:
                used_older.add(best_j)
                dup_groups += 1
                merged.append(merge_group([o, olders[best_j]]))
            else:
                merged.append(o)
        for j, e in enumerate(olders):
            if j not in used_older:
                merged.append(e)
    return merged, dup_groups


def _text_score(a: dict, b: dict) -> float:
    score = 0.0
    if a.get("category") and a.get("category") == b.get("category"):
        score += 3
    ot = f"{a.get('title', '')} {a.get('notes', '')}".lower()
    et = f"{b.get('title', '')} {b.get('notes', '')}".lower()
    o_tokens = {t for t in re.split(r"\W+", ot) if len(t) > 2}
    e_tokens = {t for t in re.split(r"\W+", et) if len(t) > 2}
    if o_tokens and e_tokens:
        score += len(o_tokens & e_tokens)
    return score


def dedupe_near_day(records: list[dict], max_day_gap: int = 3) -> tuple[list[dict], int]:
    """
    Second pass: cross-source rows with the same amount/type within a few days
    and a strong title/category match are the same logged expense (date drift).
    """
    already = [r for r in records if "," in (r.get("source") or "")]
    olds = [r for r in records if r.get("source") == "old_budget"]
    olders = [r for r in records if r.get("source") == "older_expenses"]

    used_older: set[int] = set()
    result: list[dict] = list(already)
    near_merged = 0

    for o in olds:
        best_j = None
        best_score = 2.5  # require some title/category signal
        for j, e in enumerate(olders):
            if j in used_older:
                continue
            if o["type"] != e["type"]:
                continue
            if abs(o["amount"] - e["amount"]) > 0.01:
                continue
            day_gap = abs((o["date"].date() - e["date"].date()).days)
            if day_gap == 0 or day_gap > max_day_gap:
                continue
            score = _text_score(o, e) - day_gap * 0.1
            if score > best_score:
                best_score = score
                best_j = j
        if best_j is not None:
            used_older.add(best_j)
            near_merged += 1
            result.append(merge_group([o, olders[best_j]]))
            print(
                f"near-day merge: {o['date'].date()} {o['title']!r} "
                f"<-> {olders[best_j]['date'].date()} {olders[best_j]['title']!r} "
                f"amt={o['amount']}"
            )
        else:
            result.append(o)

    for j, e in enumerate(olders):
        if j not in used_older:
            result.append(e)

    return result, near_merged


def write_output(records: list[dict]) -> None:
    records = sorted(records, key=lambda r: r["date"], reverse=True)
    # Match app export: UTF-8 with single BOM prefix
    with OUTPUT.open("w", encoding="utf-8", newline="") as f:
        f.write("\ufeff")
        f.write(",".join(HEADER) + "\n")
        for rec in records:
            row = [
                uuid.uuid4().hex[:12],
                rec["date"].strftime("%Y-%m-%d %H:%M"),
                rec["type"],
                (rec.get("title") or "").strip(),
                f"{rec['amount']:.2f}",
                rec.get("category") or "",
                rec.get("category_id") or "",
                rec.get("account") or "Main Wallet",
                rec.get("account_id") or "card_main",
                rec.get("payment_method") or "Card",
                (rec.get("notes") or "").strip(),
            ]
            f.write(",".join(escape_csv_field(c) for c in row) + "\n")


def main() -> None:
    old = load_old_budget()
    older, undated_assigned = load_older_expenses()
    print(f"old_budget records: {len(old)}")
    print(f"older_expenses records: {len(older)}")
    if undated_assigned:
        print(f"older_expenses undated rows date-inferred ({len(undated_assigned)}):")
        for line in undated_assigned:
            print(f"  - {line}")

    combined = old + older
    print(f"total before cleanup: {len(combined)}")

    combined = drop_covered_aggregates(combined)
    print(f"after aggregate drop: {len(combined)}")

    merged, dup_groups = dedupe(combined)
    print(f"same-day cross-source merges: {dup_groups}")
    print(f"after same-day dedup: {len(merged)}")

    merged, near = dedupe_near_day(merged, max_day_gap=3)
    print(f"near-day cross-source merges: {near}")
    print(f"final row count: {len(merged)}")

    write_output(merged)
    print(f"Wrote {OUTPUT}")

    print("by type:", Counter(r["type"] for r in merged))
    print("by category:", Counter(r["category"] for r in merged))
    print(
        "date range:",
        min(r["date"] for r in merged),
        "->",
        max(r["date"] for r in merged),
    )
    exp = sum(r["amount"] for r in merged if r["type"] == "expense")
    inc = sum(r["amount"] for r in merged if r["type"] == "income")
    print(f"total expense: {exp:.2f}")
    print(f"total income: {inc:.2f}")

    # Sanity: spot-check known overlap (Uber airport Dec 1 2025, 642)
    hits = [
        r
        for r in merged
        if r["date"].date().isoformat() == "2025-12-01" and abs(r["amount"] - 642) < 0.01
    ]
    print(f"sanity Dec 1 642 rows (expect 1): {len(hits)}")
    if hits:
        print("  ->", hits[0]["title"], hits[0].get("sources", hits[0]["source"]))


if __name__ == "__main__":
    main()
