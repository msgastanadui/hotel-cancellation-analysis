-- =====================================================================
-- Who Cancels? A Hotel Booking Risk Analysis
-- SQL analysis (DuckDB) on data/clean/clean_bookings.csv
-- Table: bookings (117,399 rows after cleaning)
-- =====================================================================

-- Setup -----------------------------------------------------------------
-- CREATE TABLE bookings AS
-- SELECT * FROM read_csv_auto('data/clean/clean_bookings.csv');


-- ---------------------------------------------------------------------
-- 1. Overall cancellation rate
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS total_bookings,
       ROUND(AVG(is_canceled) * 100, 1) AS cancellation_rate_pct
FROM bookings;


-- ---------------------------------------------------------------------
-- 2. Cancellation by hotel
-- ---------------------------------------------------------------------
SELECT hotel,
       COUNT(*) AS total_bookings,
       ROUND(AVG(is_canceled) * 100, 1) AS cancellation_rate_pct
FROM bookings
GROUP BY hotel
ORDER BY cancellation_rate_pct DESC;


-- ---------------------------------------------------------------------
-- 3. Cancellation by market segment (rate + share of all cancellations)
-- ---------------------------------------------------------------------
SELECT market_segment,
       COUNT(*) AS total_bookings,
       SUM(is_canceled) AS canceled_bookings,
       ROUND(AVG(is_canceled) * 100, 1) AS cancellation_rate_pct,
       ROUND(SUM(is_canceled) * 100.0 / SUM(SUM(is_canceled)) OVER (), 1) AS share_of_cancellations_pct
FROM bookings
GROUP BY market_segment
ORDER BY canceled_bookings DESC;


-- ---------------------------------------------------------------------
-- 4. Cancellation by lead time group
-- ---------------------------------------------------------------------
SELECT lead_time_group,
       COUNT(*) AS total_bookings,
       SUM(is_canceled) AS canceled_bookings,
       ROUND(AVG(is_canceled) * 100, 1) AS cancellation_rate_pct,
       ROUND(SUM(is_canceled) * 100.0 / SUM(SUM(is_canceled)) OVER (), 1) AS share_of_cancellations_pct
FROM bookings
GROUP BY lead_time_group
ORDER BY MIN(lead_time);


-- ---------------------------------------------------------------------
-- 5. Revenue lost to cancellations by market segment
-- ---------------------------------------------------------------------
SELECT market_segment,
       ROUND(SUM(CASE WHEN is_canceled = 1 THEN revenue END), 0) AS revenue_lost,
       ROUND(SUM(CASE WHEN is_canceled = 1 THEN revenue END) * 100.0 /
             SUM(SUM(CASE WHEN is_canceled = 1 THEN revenue END)) OVER (), 1) AS share_of_revenue_lost_pct
FROM bookings
GROUP BY market_segment
ORDER BY revenue_lost DESC;


-- ---------------------------------------------------------------------
-- 6. Cancellation by deposit type
-- ---------------------------------------------------------------------
SELECT deposit_type,
       COUNT(*) AS total_bookings,
       SUM(is_canceled) AS canceled_bookings,
       ROUND(AVG(is_canceled) * 100, 1) AS cancellation_rate_pct,
       ROUND(SUM(is_canceled) * 100.0 / SUM(SUM(is_canceled)) OVER (), 1) AS share_of_cancellations_pct
FROM bookings
GROUP BY deposit_type
ORDER BY canceled_bookings DESC;


-- ---------------------------------------------------------------------
-- 7. Revenue lost by deposit type
-- Scenario A: all canceled revenue is lost (sum of all rows)
-- Scenario B: Non Refund cancellations are treated as retained revenue
--             (lost = No Deposit + Refundable)
-- ---------------------------------------------------------------------
SELECT deposit_type,
       ROUND(SUM(CASE WHEN is_canceled = 1 THEN revenue END), 0) AS revenue_lost,
       ROUND(SUM(CASE WHEN is_canceled = 1 THEN revenue END) * 100.0 /
             SUM(SUM(CASE WHEN is_canceled = 1 THEN revenue END)) OVER (), 1) AS share_of_revenue_lost_pct
FROM bookings
GROUP BY deposit_type
ORDER BY revenue_lost DESC;


-- ---------------------------------------------------------------------
-- 8. Non Refund bookings by market segment
-- ---------------------------------------------------------------------
SELECT market_segment,
       COUNT(*) AS total_bookings,
       ROUND(AVG(is_canceled) * 100, 1) AS cancellation_rate_pct
FROM bookings
WHERE deposit_type = 'Non Refund'
GROUP BY market_segment
ORDER BY total_bookings DESC;


-- ---------------------------------------------------------------------
-- 9. Non Refund bookings by country (top 5)
-- ---------------------------------------------------------------------
SELECT country,
       COUNT(*) AS total_bookings,
       ROUND(AVG(is_canceled) * 100, 1) AS cancellation_rate_pct
FROM bookings
WHERE deposit_type = 'Non Refund'
GROUP BY country
ORDER BY total_bookings DESC
LIMIT 5;


-- ---------------------------------------------------------------------
-- 10. Seasonality: cancellation by arrival month and hotel
-- Note: Jul-Aug have 3 years of data, other months only 2.
-- Compare rates, not volumes.
-- ---------------------------------------------------------------------
SELECT MONTH(CAST(arrival_date AS DATE)) AS month_num,
       hotel,
       COUNT(*) AS total_bookings,
       ROUND(AVG(is_canceled) * 100, 1) AS cancellation_rate_pct
FROM bookings
GROUP BY month_num, hotel
ORDER BY month_num, hotel;


-- ---------------------------------------------------------------------
-- 11. Top 10 countries by volume
-- ---------------------------------------------------------------------
SELECT country,
       COUNT(*) AS total_bookings,
       SUM(is_canceled) AS canceled_bookings,
       ROUND(AVG(is_canceled) * 100, 1) AS cancellation_rate_pct,
       ROUND(SUM(is_canceled) * 100.0 / SUM(SUM(is_canceled)) OVER (), 1) AS share_of_cancellations_pct
FROM bookings
GROUP BY country
ORDER BY total_bookings DESC
LIMIT 10;


-- ---------------------------------------------------------------------
-- 12. Portugal vs. other countries, controlling for deposit type
-- ---------------------------------------------------------------------
SELECT CASE WHEN country = 'PRT' THEN 'Portugal' ELSE 'Other countries' END AS origin,
       deposit_type,
       COUNT(*) AS total_bookings,
       ROUND(AVG(is_canceled) * 100, 1) AS cancellation_rate_pct
FROM bookings
GROUP BY origin, deposit_type
ORDER BY origin, total_bookings DESC;


-- ---------------------------------------------------------------------
-- 13. Special requests (association, not causation)
-- ---------------------------------------------------------------------
SELECT CASE WHEN total_of_special_requests = 0 THEN '0 requests'
            ELSE '1+ requests' END AS special_requests,
       COUNT(*) AS total_bookings,
       ROUND(AVG(is_canceled) * 100, 1) AS cancellation_rate_pct,
       ROUND(SUM(is_canceled) * 100.0 / SUM(SUM(is_canceled)) OVER (), 1) AS share_of_cancellations_pct
FROM bookings
GROUP BY special_requests
ORDER BY special_requests;


-- ---------------------------------------------------------------------
-- 14. Cancellation by customer type
-- Note: customer_type = 'Group' is not the same as market_segment = 'Groups'.
-- ---------------------------------------------------------------------
SELECT customer_type,
       COUNT(*) AS total_bookings,
       ROUND(AVG(is_canceled) * 100, 1) AS cancellation_rate_pct,
       ROUND(SUM(is_canceled) * 100.0 / SUM(SUM(is_canceled)) OVER (), 1) AS share_of_cancellations_pct
FROM bookings
GROUP BY customer_type
ORDER BY total_bookings DESC;


-- ---------------------------------------------------------------------
-- 15. Previous cancellations
-- ---------------------------------------------------------------------
SELECT CASE WHEN previous_cancellations = 0 THEN '0'
            WHEN previous_cancellations = 1 THEN '1'
            ELSE '2+' END AS previous_cancellations,
       COUNT(*) AS total_bookings,
       ROUND(AVG(is_canceled) * 100, 1) AS cancellation_rate_pct
FROM bookings
GROUP BY 1
ORDER BY 1;


-- ---------------------------------------------------------------------
-- 16. Previous cancellations = 1, split by deposit type
-- (shows the 94.7% rate is inflated by Non Refund bookings)
-- ---------------------------------------------------------------------
SELECT deposit_type,
       COUNT(*) AS total_bookings,
       ROUND(AVG(is_canceled) * 100, 1) AS cancellation_rate_pct
FROM bookings
WHERE previous_cancellations = 1
GROUP BY deposit_type
ORDER BY total_bookings DESC;
