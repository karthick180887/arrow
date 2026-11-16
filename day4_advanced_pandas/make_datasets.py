"""Generate the synthetic retail datasets used by every notebook in this track.

Usage:  python make_datasets.py

All data is fake. A fixed random seed makes every run produce identical files,
so the outputs saved in the notebooks stay reproducible.
"""
from __future__ import annotations

import json
import sqlite3
from pathlib import Path

import numpy as np
import pandas as pd

HERE = Path(__file__).resolve().parent
SEED = 42

FIRST = [
    "Aarav", "Priya", "Rohan", "Ananya", "Vikram", "Meera", "Arjun", "Kavya", "Liam", "Olivia",
    "Noah", "Emma", "Lucas", "Sofia", "Ethan", "Chloe", "Mateo", "Isabella", "Hugo", "Lea",
    "Jonas", "Mia", "Felix", "Hannah", "Diego", "Lucia", "Owen", "Grace", "Ryan", "Zoe",
]
LAST = [
    "Sharma", "Patel", "Iyer", "Reddy", "Nair", "Gupta", "Menon", "Singh", "Smith", "Jones",
    "Brown", "Taylor", "Wilson", "Murphy", "Kelly", "Martin", "Dubois", "Bernard", "Moreau", "Schmidt",
    "Fischer", "Weber", "Garcia", "Lopez", "Fernandez", "Johnson", "Miller", "Davis", "Tremblay", "Roy",
]
CITIES = [
    ("London", "UK"), ("Manchester", "UK"), ("Dublin", "Ireland"), ("Paris", "France"),
    ("Lyon", "France"), ("Berlin", "Germany"), ("Munich", "Germany"), ("Madrid", "Spain"),
    ("Mumbai", "India"), ("Bengaluru", "India"), ("Chennai", "India"), ("New York", "USA"),
    ("Chicago", "USA"), ("Toronto", "Canada"),
]
SEGMENTS = ["Consumer", "Corporate", "Small Business"]
CATALOGUE = {
    "Electronics": [
        ("Wireless Mouse", 24.99), ("Mechanical Keyboard", 89.0), ("USB-C Hub", 39.5),
        ("Noise-Cancelling Headphones", 199.0), ("Webcam 1080p", 59.0), ("Portable SSD 1TB", 109.0),
        ("Bluetooth Speaker", 49.9), ("Smart Watch", 179.0),
    ],
    "Home": [
        ("Electric Kettle", 34.5), ("Air Fryer", 119.0), ("Desk Lamp", 27.0), ("Memory Foam Pillow", 42.0),
        ("Cast Iron Pan", 38.0), ("Vacuum Flask", 21.5), ("Wall Clock", 18.0), ("Storage Box Set", 29.0),
    ],
    "Sports": [
        ("Yoga Mat", 25.0), ("Resistance Bands", 15.5), ("Running Shoes", 95.0), ("Cycling Helmet", 64.0),
        ("Dumbbell Pair 5kg", 45.0), ("Skipping Rope", 9.9), ("Tennis Racket", 129.0), ("Water Bottle", 12.0),
    ],
    "Books": [
        ("Python Basics Guide", 32.0), ("SQL Query Workbook", 41.0), ("Data Science Handbook", 48.0),
        ("Statistics Primer", 27.5), ("Clean Coding Guide", 36.0), ("Data Systems Design", 52.0),
        ("Charts That Work", 30.0), ("Pandas in Practice", 39.0),
    ],
    "Toys": [
        ("Building Blocks 500pc", 44.0), ("Puzzle 1000pc", 16.0), ("Remote Control Car", 58.0),
        ("Board Game Classic", 28.0), ("Plush Bear", 14.5), ("Science Kit", 35.0),
        ("Drawing Tablet Kids", 49.0), ("Kite", 11.0),
    ],
}
# The last three products are never ordered: useful for outer joins and anti-joins.
UNSOLD_PRODUCTS = 3
# The last twenty customers never place an order.
INACTIVE_CUSTOMERS = 20

STAFF_PLAN = (
    [
        ("S01", "Chief Executive", "Management", None, 180000),
        ("S02", "Head of Sales", "Sales", "S01", 120000),
        ("S03", "Head of Support", "Support", "S01", 105000),
        ("S04", "Head of Operations", "Operations", "S01", 110000),
        ("S05", "Sales Team Lead", "Sales", "S02", 78000),
        ("S06", "Sales Team Lead", "Sales", "S02", 78000),
    ]
    + [(f"S{n:02d}", "Sales Rep", "Sales", "S05" if n <= 10 else "S06", 46000) for n in range(7, 15)]
    + [(f"S{n:02d}", "Support Agent", "Support", "S03", 40000) for n in range(15, 20)]
    + [(f"S{n:02d}", "Operations Analyst", "Operations", "S04", 52000) for n in range(20, 25)]
)
SALES_REPS = [f"S{n:02d}" for n in range(7, 15)]


def make_customers(rng: np.random.Generator, n: int = 250) -> pd.DataFrame:
    rows = []
    for i in range(1, n + 1):
        first = FIRST[rng.integers(len(FIRST))]
        last = LAST[rng.integers(len(LAST))]
        city, country = CITIES[rng.integers(len(CITIES))]
        signup = pd.Timestamp("2022-01-01") + pd.Timedelta(days=int(rng.integers(0, 730)))
        rows.append(
            {
                "customer_id": f"C{i:04d}",
                "name": f"{first} {last}",
                "email": f"{first}.{last}{i}@example.com".lower(),
                "city": city,
                "country": country,
                "segment": SEGMENTS[rng.choice(3, p=[0.6, 0.25, 0.15])],
                "signup_date": signup.strftime("%Y-%m-%d"),
            }
        )
    return pd.DataFrame(rows)


def make_products(rng: np.random.Generator) -> pd.DataFrame:
    rows = []
    n = 0
    for category, items in CATALOGUE.items():
        for name, price in items:
            n += 1
            rows.append(
                {
                    "product_id": f"P{n:03d}",
                    "product_name": name,
                    "category": category,
                    "unit_price": price,
                    "unit_cost": round(price * rng.uniform(0.45, 0.75), 2),
                }
            )
    return pd.DataFrame(rows)


def make_staff(rng: np.random.Generator) -> pd.DataFrame:
    rows = []
    used: set[str] = set()
    for staff_id, role, department, manager_id, base in STAFF_PLAN:
        while True:
            name = f"{FIRST[rng.integers(len(FIRST))]} {LAST[rng.integers(len(LAST))]}"
            if name not in used:
                used.add(name)
                break
        bump = 0 if role.startswith(("Chief", "Head")) else int(rng.choice([0, 2000, 4000, 6000]))
        hired = pd.Timestamp("2018-01-01") + pd.Timedelta(days=int(rng.integers(0, 2400)))
        rows.append(
            {
                "staff_id": staff_id,
                "name": name,
                "role": role,
                "department": department,
                "manager_id": manager_id,
                "salary": base + bump,
                "hire_date": hired.strftime("%Y-%m-%d"),
            }
        )
    return pd.DataFrame(rows)


def make_orders(rng: np.random.Generator, customers: pd.DataFrame, n: int = 2000) -> pd.DataFrame:
    dates = pd.date_range("2024-01-01", "2025-06-30", freq="D")
    weekday = np.array([1.0, 1.0, 1.05, 1.1, 1.25, 1.4, 1.2])[dates.day_of_week]
    trend = np.linspace(1.0, 1.6, len(dates))
    festive = np.where(
        ((dates.month == 11) & (dates.day >= 20)) | ((dates.month == 12) & (dates.day <= 24)), 1.8, 1.0
    )
    weights = weekday * trend * festive
    picked = np.sort(rng.choice(len(dates), size=n, p=weights / weights.sum()))

    active = customers["customer_id"].to_numpy()[: len(customers) - INACTIVE_CUSTOMERS]
    popularity = rng.pareto(1.5, len(active)) + 0.2
    buyer = rng.choice(active, size=n, p=popularity / popularity.sum())

    status = rng.choice(["completed", "shipped", "cancelled", "returned"], size=n, p=[0.78, 0.08, 0.08, 0.06])
    channel = rng.choice(["web", "mobile", "store"], size=n, p=[0.5, 0.3, 0.2])
    rep = rng.choice(SALES_REPS, size=n)
    return pd.DataFrame(
        {
            "order_id": np.arange(10001, 10001 + n),
            "customer_id": buyer,
            "order_date": dates[picked].strftime("%Y-%m-%d"),
            "status": status,
            "channel": channel,
            # Only in-store orders have a sales rep; online orders leave this empty.
            "staff_id": [r if c == "store" else None for r, c in zip(rep, channel)],
        }
    )


def make_order_items(rng: np.random.Generator, orders: pd.DataFrame, products: pd.DataFrame) -> pd.DataFrame:
    sellable = products.iloc[: len(products) - UNSOLD_PRODUCTS]
    popularity = rng.uniform(0.4, 1.6, len(sellable))
    popularity = popularity / popularity.sum()
    price = dict(zip(products["product_id"], products["unit_price"]))
    rows = []
    for order_id in orders["order_id"]:
        n_lines = min(1 + int(rng.poisson(1.2)), 6)
        chosen = rng.choice(sellable["product_id"].to_numpy(), size=n_lines, replace=False, p=popularity)
        for line_no, product_id in enumerate(chosen, start=1):
            rows.append(
                {
                    "order_id": int(order_id),
                    "line_no": line_no,
                    "product_id": str(product_id),
                    "quantity": int(rng.choice([1, 2, 3, 4, 5], p=[0.5, 0.25, 0.13, 0.07, 0.05])),
                    "unit_price": price[str(product_id)],
                    "discount": float(rng.choice([0.0, 0.05, 0.10, 0.15, 0.20], p=[0.6, 0.12, 0.14, 0.08, 0.06])),
                }
            )
    return pd.DataFrame(rows)


STATUS_VARIANTS = {
    "completed": ["completed", "completed", "completed", "Completed", "COMPLETED", " completed "],
    "shipped": ["shipped", "shipped", "Shipped", "SHIPPED "],
    "cancelled": ["cancelled", "cancelled", "Cancelled", "canceled"],
    "returned": ["returned", "returned", "Returned", " RETURNED"],
}


def make_orders_raw(
    rng: np.random.Generator,
    orders: pd.DataFrame,
    items: pd.DataFrame,
    customers: pd.DataFrame,
    n: int = 380,
) -> pd.DataFrame:
    """A deliberately messy export of the same orders, for cleaning and data-quality lessons."""
    totals = (
        items.assign(amount=items["quantity"] * items["unit_price"] * (1 - items["discount"]))
        .groupby("order_id")
        .agg(quantity=("quantity", "sum"), amount=("amount", "sum"))
    )
    sample = (
        orders.sample(n, random_state=SEED)
        .merge(totals, left_on="order_id", right_index=True)
        .merge(customers[["customer_id", "email"]], on="customer_id")
    )
    rows = []
    for rec in sample.itertuples(index=False):
        day = pd.Timestamp(rec.order_date)
        roll = rng.random()
        if roll < 0.70:
            date_text = day.strftime("%Y-%m-%d")
        elif roll < 0.85:
            date_text = day.strftime("%d/%m/%Y")
        elif roll < 0.96:
            date_text = day.strftime("%b %d, %Y")
        elif roll < 0.98:
            date_text = ""
        else:
            date_text = (day + pd.DateOffset(years=6)).strftime("%Y-%m-%d")

        variants = STATUS_VARIANTS[rec.status]
        status_text = variants[rng.integers(len(variants))]

        roll = rng.random()
        if roll < 0.55:
            amount_text = f"{rec.amount:.2f}"
        elif roll < 0.86:
            amount_text = f"${rec.amount:,.2f}"
        elif roll < 0.92:
            amount_text = ""
        elif roll < 0.96:
            amount_text = f"-{rec.amount:.2f}"
        else:
            amount_text = f"{rec.amount * 100:.2f}"

        roll = rng.random()
        if roll < 0.90:
            quantity_text = str(rec.quantity)
        elif roll < 0.94:
            quantity_text = "0"
        elif roll < 0.96:
            quantity_text = "-1"
        elif roll < 0.98:
            quantity_text = "N/A"
        else:
            quantity_text = ""

        roll = rng.random()
        if roll < 0.90:
            customer_text = rec.customer_id
        elif roll < 0.95:
            customer_text = rec.customer_id.lower()
        elif roll < 0.98:
            customer_text = "C9999"
        else:
            customer_text = ""

        roll = rng.random()
        if roll < 0.92:
            email_text = rec.email
        elif roll < 0.96:
            email_text = rec.email.replace("@", " at ")
        else:
            email_text = ""

        rows.append(
            {
                "order_id": rec.order_id,
                "customer_id": customer_text,
                "email": email_text,
                "order_date": date_text,
                "status": status_text,
                "channel": rec.channel,
                "quantity": quantity_text,
                "amount": amount_text,
            }
        )
    raw = pd.DataFrame(rows)
    exact_duplicates = raw.sample(15, random_state=1)
    conflicting = raw.sample(6, random_state=2).assign(amount="1.00")
    raw = pd.concat([raw, exact_duplicates, conflicting], ignore_index=True)
    return raw.sample(frac=1, random_state=3).reset_index(drop=True)


def make_site_traffic(rng: np.random.Generator) -> pd.DataFrame:
    """Hourly website traffic with planted gaps (missing rows) and NaNs (missing values)."""
    idx = pd.date_range("2025-01-01", "2025-03-31 23:00", freq="h")
    hour = idx.hour.to_numpy()
    hour_curve = 0.35 + 0.65 * np.exp(-((hour - 20) ** 2) / 18) + 0.45 * np.exp(-((hour - 12) ** 2) / 10)
    weekday = np.array([1.0, 1.0, 1.0, 1.05, 1.15, 1.3, 1.25])[idx.day_of_week]
    trend = np.linspace(1.0, 1.25, len(idx))
    sessions = rng.poisson(220 * hour_curve * weekday * trend).astype(float)
    conversions = rng.binomial(sessions.astype(int), 0.032).astype(float)
    load = rng.normal(420, 35, len(idx))
    slow = rng.choice(len(idx), size=25, replace=False)
    load[slow] += rng.uniform(400, 1200, size=25)

    # Missing values: scattered tracking failures plus one 12-hour outage.
    lost = rng.choice(len(idx), size=60, replace=False)
    sessions[lost] = np.nan
    conversions[lost] = np.nan
    outage = (idx >= "2025-02-10 03:00") & (idx <= "2025-02-10 14:00")
    sessions[outage] = np.nan
    conversions[outage] = np.nan
    load[rng.choice(len(idx), size=100, replace=False)] = np.nan

    traffic = pd.DataFrame(
        {
            "timestamp": idx.strftime("%Y-%m-%d %H:%M:%S"),
            "sessions": pd.array(sessions, dtype="Float64").astype("Int64"),
            "conversions": pd.array(conversions, dtype="Float64").astype("Int64"),
            "avg_load_ms": np.round(load, 1),
        }
    )
    # Missing rows: a six-hour logging gap plus thirty scattered hours.
    gap = (idx >= "2025-03-05 01:00") & (idx <= "2025-03-05 06:00")
    scattered = np.zeros(len(idx), dtype=bool)
    scattered[rng.choice(len(idx), size=30, replace=False)] = True
    return traffic[~(gap | scattered)].reset_index(drop=True)


def make_orders_api(
    rng: np.random.Generator,
    orders: pd.DataFrame,
    items: pd.DataFrame,
    customers: pd.DataFrame,
    products: pd.DataFrame,
    n: int = 60,
) -> list[dict]:
    """The latest orders shaped like a nested JSON API response."""
    customer = customers.set_index("customer_id")
    product = products.set_index("product_id")
    payload = []
    for order in orders.tail(n).itertuples(index=False):
        who = customer.loc[order.customer_id]
        lines = items[items["order_id"] == order.order_id]
        record = {
            "order_id": int(order.order_id),
            "placed_at": f"{order.order_date}T{int(rng.integers(7, 23)):02d}:{int(rng.integers(0, 60)):02d}:00Z",
            "status": order.status,
            "channel": order.channel,
            "customer": {
                "id": order.customer_id,
                "name": who["name"],
                "email": who["email"],
                "segment": who["segment"],
            },
            "items": [
                {
                    "product_id": line.product_id,
                    "name": product.loc[line.product_id, "product_name"],
                    "category": product.loc[line.product_id, "category"],
                    "quantity": int(line.quantity),
                    "unit_price": float(line.unit_price),
                    "discount": float(line.discount),
                }
                for line in lines.itertuples(index=False)
            ],
            "notes": "gift wrap" if rng.random() < 0.15 else None,
        }
        # In-store orders are collected in person, so they have no shipping block at all.
        if order.channel != "store":
            record["shipping"] = {"city": who["city"], "country": who["country"]}
        payload.append(record)
    return payload


SCHEMA = """
CREATE TABLE customers (
    customer_id TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    email       TEXT NOT NULL,
    city        TEXT NOT NULL,
    country     TEXT NOT NULL,
    segment     TEXT NOT NULL,
    signup_date TEXT NOT NULL
);
CREATE TABLE products (
    product_id   TEXT PRIMARY KEY,
    product_name TEXT NOT NULL,
    category     TEXT NOT NULL,
    unit_price   REAL NOT NULL,
    unit_cost    REAL NOT NULL
);
CREATE TABLE staff (
    staff_id   TEXT PRIMARY KEY,
    name       TEXT NOT NULL,
    role       TEXT NOT NULL,
    department TEXT NOT NULL,
    manager_id TEXT REFERENCES staff (staff_id),
    salary     INTEGER NOT NULL,
    hire_date  TEXT NOT NULL
);
CREATE TABLE orders (
    order_id    INTEGER PRIMARY KEY,
    customer_id TEXT NOT NULL REFERENCES customers (customer_id),
    order_date  TEXT NOT NULL,
    status      TEXT NOT NULL,
    channel     TEXT NOT NULL,
    staff_id    TEXT REFERENCES staff (staff_id)
);
CREATE TABLE order_items (
    order_id   INTEGER NOT NULL REFERENCES orders (order_id),
    line_no    INTEGER NOT NULL,
    product_id TEXT NOT NULL REFERENCES products (product_id),
    quantity   INTEGER NOT NULL,
    unit_price REAL NOT NULL,
    discount   REAL NOT NULL,
    PRIMARY KEY (order_id, line_no)
);
CREATE INDEX idx_orders_customer ON orders (customer_id);
CREATE INDEX idx_orders_date ON orders (order_date);
CREATE INDEX idx_items_product ON order_items (product_id);
"""


def _plain(value: object) -> object:
    """Convert pandas/NumPy scalars to the plain Python types sqlite3 understands."""
    if value is None or value is pd.NA or (isinstance(value, float) and np.isnan(value)):
        return None
    if isinstance(value, np.generic):
        return value.item()
    return value


def write_database(path: Path, tables: dict[str, pd.DataFrame]) -> None:
    path.unlink(missing_ok=True)
    conn = sqlite3.connect(path)
    try:
        conn.executescript(SCHEMA)
        for name, frame in tables.items():
            placeholders = ", ".join("?" * frame.shape[1])
            rows = [tuple(_plain(v) for v in row) for row in frame.itertuples(index=False, name=None)]
            conn.executemany(f"INSERT INTO {name} VALUES ({placeholders})", rows)
        conn.commit()
    finally:
        conn.close()


def main() -> None:
    rng = np.random.default_rng(SEED)
    customers = make_customers(rng)
    products = make_products(rng)
    staff = make_staff(rng)
    orders = make_orders(rng, customers)
    items = make_order_items(rng, orders, products)
    orders_raw = make_orders_raw(rng, orders, items, customers)
    traffic = make_site_traffic(rng)
    api = make_orders_api(rng, orders, items, customers, products)

    csv_files = {
        "customers.csv": customers,
        "products.csv": products,
        "staff.csv": staff,
        "orders.csv": orders,
        "order_items.csv": items,
        "orders_raw.csv": orders_raw,
        "site_traffic.csv": traffic,
    }
    for name, frame in csv_files.items():
        frame.to_csv(HERE / name, index=False)
        print(f"{name:<18} {len(frame):>6} rows  {frame.shape[1]} columns")

    (HERE / "orders_api.json").write_text(json.dumps(api, indent=2), encoding="utf-8")
    print(f"{'orders_api.json':<18} {len(api):>6} records")

    write_database(
        HERE / "retail.db",
        {"customers": customers, "products": products, "staff": staff, "orders": orders, "order_items": items},
    )
    print(f"{'retail.db':<18} 5 tables")


if __name__ == "__main__":
    main()
