-- Walmart Sales Analysis (SQLite)
-- Dataset: Kaggle Walmart Recruiting - Store Sales Forecasting
-- Tables: train(Store, Dept, Date, Weekly_Sales, IsHoliday)
--         stores(Store, Type, Size)
--         features(Store, Date, Temperature, Fuel_Price, MarkDown1-5, CPI, Unemployment, IsHoliday)

-- ============ 0. SETUP (sqlite3 CLI) ============
-- .mode csv
-- .import --skip 1 train.csv train
-- .import --skip 1 stores.csv stores
-- .import --skip 1 features.csv features_raw
-- CREATE TABLE features AS
-- SELECT Store, Date, Temperature, Fuel_Price,
--   NULLIF(MarkDown1,'NA') AS MarkDown1, NULLIF(MarkDown2,'NA') AS MarkDown2,
--   NULLIF(MarkDown3,'NA') AS MarkDown3, NULLIF(MarkDown4,'NA') AS MarkDown4,
--   NULLIF(MarkDown5,'NA') AS MarkDown5, NULLIF(CPI,'NA') AS CPI,
--   NULLIF(Unemployment,'NA') AS Unemployment, IsHoliday
-- FROM features_raw;
-- CREATE INDEX ix_train ON train(Store, Dept, Date);

-- ============ 1. DATA QUALITY ============
-- 1.1 Size and date range
SELECT COUNT(*) AS rows_, MIN(Date) AS first_week, MAX(Date) AS last_week,
       COUNT(DISTINCT Store) AS stores, COUNT(DISTINCT Dept) AS depts
FROM train;

-- 1.2 Negative sales (likely returns)
SELECT COUNT(*) AS negative_rows FROM train WHERE Weekly_Sales < 0;

-- ============ 2. TRENDS ============
-- 2.1 Yearly sales (2012 is partial: data ends in October)
SELECT SUBSTR(Date,1,4) AS yr, ROUND(SUM(Weekly_Sales)/1e6,1) AS total_m
FROM train GROUP BY yr;

-- 2.2 Like-for-like growth (Feb to Oct only)
SELECT SUBSTR(Date,1,4) AS yr, ROUND(SUM(Weekly_Sales)/1e6,1) AS total_m
FROM train WHERE SUBSTR(Date,6,2) BETWEEN '02' AND '10' GROUP BY yr;

-- 2.3 Weekly total sales
SELECT Date, ROUND(SUM(Weekly_Sales)/1e6,1) AS total_m
FROM train GROUP BY Date ORDER BY Date;

-- 2.4 Top 5 weeks
SELECT Date, ROUND(SUM(Weekly_Sales)/1e6,1) AS total_m
FROM train GROUP BY Date ORDER BY total_m DESC LIMIT 5;

-- ============ 3. SEASONALITY ============
-- 3.1 Average weekly total by month
SELECT SUBSTR(Date,6,2) AS month,
       ROUND(SUM(Weekly_Sales)/COUNT(DISTINCT Date)/1e6,2) AS avg_weekly_total_m
FROM train GROUP BY month ORDER BY month;

-- 3.2 Holiday vs normal weeks
SELECT IsHoliday, ROUND(AVG(Weekly_Sales),0) AS avg_sales
FROM train GROUP BY IsHoliday;

-- 3.3 Holiday lift by store type
SELECT s.Type,
  ROUND(AVG(CASE WHEN t.IsHoliday=0 THEN t.Weekly_Sales END),0) AS normal_avg,
  ROUND(AVG(CASE WHEN t.IsHoliday=1 THEN t.Weekly_Sales END),0) AS holiday_avg
FROM train t JOIN stores s USING(Store) GROUP BY s.Type;

-- 3.4 Christmas check: the flagged week (31 Dec) is a dip; the peak is 24 Dec
SELECT Date, ROUND(SUM(Weekly_Sales)/1e6,1) AS total_m, MAX(IsHoliday) AS flagged
FROM train WHERE Date BETWEEN '2010-12-10' AND '2011-01-07' GROUP BY Date;

-- ============ 4. PRODUCT (DEPARTMENT) PERFORMANCE ============
-- 4.1 Top 10 departments by total sales
SELECT Dept, ROUND(SUM(Weekly_Sales)/1e6,1) AS total_m
FROM train GROUP BY Dept ORDER BY total_m DESC LIMIT 10;

-- 4.2 Most holiday-sensitive departments
SELECT Dept,
  ROUND((AVG(CASE WHEN IsHoliday=1 THEN Weekly_Sales END) /
         AVG(CASE WHEN IsHoliday=0 THEN Weekly_Sales END) - 1) * 100, 0) AS holiday_lift_pct
FROM train GROUP BY Dept
HAVING AVG(CASE WHEN IsHoliday=0 THEN Weekly_Sales END) > 1000
ORDER BY holiday_lift_pct DESC LIMIT 10;

-- ============ 5. STORE PERFORMANCE ============
-- 5.1 Top and bottom stores
SELECT t.Store, s.Type, s.Size, ROUND(SUM(t.Weekly_Sales)/1e6,1) AS total_m
FROM train t JOIN stores s USING(Store)
GROUP BY t.Store ORDER BY total_m DESC;

-- 5.2 Sales by store type
SELECT s.Type, ROUND(SUM(t.Weekly_Sales)/1e6,0) AS total_m,
       ROUND(AVG(t.Weekly_Sales),0) AS avg_dept_week
FROM train t JOIN stores s USING(Store) GROUP BY s.Type;

-- 5.3 Sales per sq ft per week, by store type
SELECT s.Type, ROUND(AVG(x.avg_week_sales / s.Size),2) AS sales_per_sqft_week
FROM (SELECT Store, SUM(Weekly_Sales)/COUNT(DISTINCT Date) AS avg_week_sales
      FROM train GROUP BY Store) x
JOIN stores s USING(Store) GROUP BY s.Type;

-- ============ 6. EXTERNAL DRIVERS ============
-- 6.1 Store-week totals joined to features (export for correlation in Python/Excel)
SELECT t.Store, t.Date, SUM(t.Weekly_Sales) AS sales,
       f.Temperature, f.Fuel_Price, f.CPI, f.Unemployment,
       COALESCE(f.MarkDown1,0)+COALESCE(f.MarkDown2,0)+COALESCE(f.MarkDown3,0)+
       COALESCE(f.MarkDown4,0)+COALESCE(f.MarkDown5,0) AS markdown_total
FROM train t JOIN features f ON t.Store=f.Store AND t.Date=f.Date
GROUP BY t.Store, t.Date;
-- Findings: markdown correlation ~0.11 (Nov 2011 onward); temperature -0.10;
-- fuel price -0.04; CPI 0.02; unemployment -0.05 (each after removing store-size effect).
