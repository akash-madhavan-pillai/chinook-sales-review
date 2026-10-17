# Chinook Music Store: Sales & Customer Health Review

Analysis of Chinook Music Store's transactional database — 59 customers, 412 invoices, and $2,328 in revenue over five trading years (2009–2013). Produced as a sales leadership review covering revenue concentration, catalogue performance, and customer retention risk.

## Key Findings

- **Revenue is highly diversified.** The top 10 customers generate only 19.4% of revenue, and no single customer exceeds 2.1%. There is no key-account risk.
- **43% of the catalogue has never sold, but this is mainly a volume problem.** With only 2,240 purchases for 3,503 tracks, 36% would be unsold even if every purchase were a different track.
- **Four genres drive 73.5% of revenue,** yet they earn almost exactly their share of the catalogue. They are big, not unusually efficient.
- **23 overdue customers hold 38.7% of lifetime customer value.** Six of them are high-value, including two of the top three spenders, and should be contacted first.

Both Q1 and Q2 point to the same conclusion: growth depends on **more customers and more purchases**, not on protecting a few accounts or cutting the catalogue.

## Business Questions

This project answers three questions the sales leadership team would ask before setting the next quarter's strategy:

**1. How concentrated is our customer revenue?**  
*Stakeholder: Head of Sales.* Understanding revenue concentration tells us whether losing one or two accounts would threaten the business, and where account management effort should focus.

**2. What percentage of the catalogue is dead inventory, and where does revenue actually come from?**  
*Stakeholder: Head of Product / Merchandising.* Identifying tracks and genres that never sell reveals opportunities to rationalise the catalogue or run targeted promotions on unsold stock.

**3. Which customers are at risk of churning, and which of them are worth saving?**  
*Stakeholder: Head of Sales + Marketing.* Segmenting customers by risk of lapsing and lifetime value produces an actionable list for retention outreach — who to call this week, and who to let go quietly.

## Findings and Recommendations

### Q1 — Revenue concentration: low risk, volume-driven

*SQL: `sql/01_customer_concentration.sql`*

- The top 10 customers (17% of the base) generate **19.4%** of revenue, far below the 80/20 pattern typical of retail.
- The largest single customer accounts for **2.1%** (an even share would be 1.7%).
- The USA leads on total revenue (**22.5%**) because it has the most customers (13), not because Americans spend more: it ranks **8th** on spend per customer ($40.24).
- The countries with the highest average spend each have only one customer, so those averages are not reliable.

**Recommendation:** grow by acquiring more customers in markets that already perform well per head, rather than focusing on protecting a few large accounts.

### Q2 — Catalogue health: a volume problem, with revenue concentrated in four genres

*SQL: `sql/02_catalogue_health.sql`*

- **43.4%** of the catalogue (1,519 of 3,503 tracks) has never sold.
- This is mainly a volume issue: only 2,240 track purchases were made, so **36.1%** would be unsold even if every purchase were different. Repeat purchases account for just **7.3** points.
- Rock, Latin, Metal and Alternative & Punk generate **73.5%** of revenue (Rock alone 35.5%). Their revenue index (revenue share ÷ catalogue share) is close to **1.0**, so they earn roughly their fair share.
- Most small music genres earn below their share and are 50–65% unsold.
- The genres earning most per track are video content (Sci Fi & Fantasy, TV Shows, Drama, Comedy), driven by their **$1.99 price** rather than proven demand.
- **Bossa Nova** is the standout music genre: above its revenue share and only **6.7%** unsold.

**Recommendations:** focus on growing purchase volume rather than cutting the catalogue; test promotion of high-performing niches such as Bossa Nova; treat video's strong index as a pricing effect and validate demand before expanding it.

### Q3 — Churn risk: six high-value customers to contact now

*SQL: `sql/03_churn_risk.sql`*

- Risk is measured against each customer's **own** purchase rhythm: days since last purchase ÷ their average gap between purchases (the "overdue ratio").
- **23** of 59 customers are overdue (ratio above 1), and **10** have missed two or more purchase cycles.
- Combining risk with value (high value = above the $39.47 average lifetime value) gives four segments:

| Segment | Rule | Customers | Lifetime value | Share |
|---|---|---|---|---|
| **Save** | overdue + high value | 6 | $257.72 | 11.1% |
| **Let go** | overdue + low value | 17 | $642.56 | 27.6% |
| **Nurture** | not overdue + high value | 16 | $673.92 | 28.9% |
| **Monitor** | not overdue + low value | 20 | $754.40 | 32.4% |
| **Total** | | 59 | $2,328.60 | 100% |

- Overdue customers hold **$900.28 (38.7%)** of lifetime customer value.
- The Save group includes **Luis Rojas** and **Richard Cunningham**, two of the top three spenders.

**Recommendations:** personal outreach to the six Save customers this week; light-touch reminders for Let go; keep Nurture customers engaged with recommendations.

*Note: lifetime value is past spend, so these figures represent customer value at risk, not guaranteed future revenue.*

## Approach

1. **Schema discovery** (`sql/scratchpad.sql`): mapped tables, primary keys, foreign keys and nullable columns using `information_schema`.
2. **Validation** (`sql/00_validation.sql`): six layers of data-quality checks, run before any analysis.
3. **Analysis** (`sql/01_` to `sql/03_`): one file per business question, each query commented with what it answers and what it found.
4. **Reconciliation throughout:** key results were checked two ways (for example, top-10 revenue share calculated both as a combined total and as a sum of individual shares).

## Data Quality Notes

Before any analysis, a six-layer validation script (`sql/00_validation.sql`) was run. All checks passed.

- ✅ **Row counts:** all 11 tables loaded with expected volumes (e.g. 59 customers, 412 invoices, 3,503 tracks).
- ✅ **Primary keys:** every ID is unique, including the composite key on `playlisttrack`.
- ✅ **Foreign keys:** zero orphans across 11 relationships. Four nullable foreign keys were checked with guards so legitimate blanks weren't counted as errors.
- ✅ **Missing values:** no blanks in any column used by the analysis. `track.composer` is 28% blank (978 tracks) but is not used.
- ✅ **Value ranges:** invoice totals $0.99–$25.86, track prices $0.99–$1.99, invoices dated 2009–2013. No negative or zero values. Every line item has quantity 1 (expected for digital downloads).
- ✅ **Reconciliation:** revenue matches from invoice headers and line items ($2,328.60), at both grand-total and per-invoice level.

## Data Caveats

- **Chinook is a synthetic teaching database.** Distributions are artificially flat and do not reflect real-world music retail skew. For example, every customer made exactly 7 purchases except one (6), and average purchase gaps take only about six distinct values. Findings should be read as a demonstration of analytical technique rather than genuine business insight.
- **The transaction data ends in 2013.** All time-based analysis (e.g. "days since last purchase") is measured against the most recent invoice date in the dataset (2013-12-22), not today's date.
- **Small samples:** several countries and genres have only one customer or one track, so their averages and rates are flagged rather than interpreted.

## Repository Structure

```
chinook-sales-review/
├── README.md
└── sql/
    ├── scratchpad.sql                   schema discovery (run once)
    ├── 00_validation.sql                six-layer data validation (run first)
    ├── 01_customer_concentration.sql    Q1: revenue concentration
    ├── 02_catalogue_health.sql          Q2: dead inventory and genre revenue
    └── 03_churn_risk.sql                Q3: churn risk segmentation
```

## How to Reproduce

1. Install PostgreSQL (tested on version 18).
2. Download `Chinook_PostgreSql.sql` from the [lerocha/chinook-database](https://github.com/lerocha/chinook-database) repository and run it to create the database.
3. Run `sql/00_validation.sql` and confirm all checks pass.
4. Run `sql/01_customer_concentration.sql`, `sql/02_catalogue_health.sql` and `sql/03_churn_risk.sql`.

## Skills Demonstrated

- **SQL (PostgreSQL):** joins (inner, left), aggregation, `GROUP BY` / `HAVING`, subqueries (in `WHERE`, `FROM` and `SELECT`), CTEs, `CASE` segmentation, `ROLLUP`, `COALESCE`, date arithmetic.
- **Data validation:** row counts, primary-key uniqueness, foreign-key integrity with nullable-key handling, missing-value audits, range checks, reconciliation.
- **Analysis:** concentration (Pareto) analysis, sell-through and decomposition, share-of-space vs share-of-revenue indexing, recency/frequency/value (RFM-style) churn segmentation.
- **Communication:** stakeholder-framed questions, findings with recommendations, explicit caveats.