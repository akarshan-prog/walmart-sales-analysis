# Walmart Sales Analysis (SQL)

Analysis of weekly sales across 45 Walmart stores and 81 departments (Feb 2010 to Oct 2012) to find trends, seasonality and product performance.

**Live dashboard:** [https://claude.ai/artifact/VDKkCkQUpgeu8BbmuNfRPG](https://akarshan-prog.github.io/walmart-sales-analysis/)

## Tools
SQLite, SQL (joins, aggregation, CASE, subqueries), Python (pandas) for loading and cleaning, Chart.js for the dashboard.

## Data
Kaggle: [Walmart Recruiting - Store Sales Forecasting](https://www.kaggle.com/c/walmart-recruiting-store-sales-forecasting/data)

| Table | Contents | Rows |
|---|---|---|
| train | Store, Dept, Date, Weekly_Sales, IsHoliday | 421,570 |
| stores | Store, Type (A/B/C), Size | 45 |
| features | Temperature, Fuel_Price, MarkDown1-5, CPI, Unemployment | 8,190 |

**Cleaning:** "NA" values in the markdown, CPI and unemployment columns were converted to NULL. 1,285 negative sales rows were kept as returns. The dataset has no customer-level data, so customer behavior is inferred from holidays, store type and department patterns.

## Key findings
1. **Christmas drives the year.** The best week is 24 Dec 2010 ($80.9M). November and December are the strongest months.
2. **The holiday flag misses the real peak.** The flagged "Christmas" week (31 Dec) is a post-holiday dip, while the pre-Christmas week is not flagged.
3. **Thanksgiving is the top flagged holiday**, about 40% above a normal week.
4. **Holiday-sensitive departments:** 72, 6, 18, 55 and 5 gain 58% to 101% in holiday weeks.
5. **Store type matters.** Type A stores sell the most per department-week ($20.1K), but small Type C stores earn the most per sq ft. Type C shows no holiday lift.
6. **Growth is flat.** Feb to Oct sales were $1.80B (2010), $1.79B (2011) and $1.83B (2012), a 2.5% rise overall.
7. **External factors matter little.** Markdowns have a weak link to sales (correlation 0.11). Temperature, fuel price, CPI and unemployment are close to zero.

## Recommendations
- Plan stock and staffing for November and December first, especially the week before Christmas.
- Prioritize holiday-sensitive departments (72, 6, 18) in promotions and inventory.
- Test markdowns by department rather than chain-wide, since the overall effect is small.
- Review Type C store formats, which earn the most per sq ft.

## Files
- `walmart_analysis.sql`: 15 documented queries
- `walmart.db`: cleaned SQLite database
- `walmart_dashboard.html`: dashboard page
- Live dashboard: link above

## Limitations
2012 is a partial year, markdown data starts in Nov 2011, and correlations do not prove cause and effect.
