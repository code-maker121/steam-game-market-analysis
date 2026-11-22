-- ============================================================
-- Steam Game Market & Portfolio Analysis
-- SQL Showcase Project
-- Environment: MotherDuck / DuckDB
-- Source table: steam_games
--
-- Project approach:
-- This script intentionally preserves meaningful exploratory
-- analysis so the progression from data validation to KPI design,
-- anomaly investigation, segmentation, and ranking is visible.
-- Pure syntax tests and fully superseded duplicate queries were
-- removed.
-- ============================================================


-- ============================================================
-- SECTION 1 — DATA UNDERSTANDING & QUALITY VALIDATION
-- ============================================================

-- 1.1 Inspect table schema
DESCRIBE steam_games;


-- 1.2 Preview core analytical fields
SELECT
    appID,
    name,
    release_date,
    estimated_owners,
    price,
    peak_ccu
FROM steam_games
LIMIT 10;


-- 1.3 Check completeness of core fields
SELECT
    COUNT(*) AS total_rows,
    COUNT(name) AS name_count,
    COUNT(price) AS price_count,
    COUNT(estimated_owners) AS owner_count,
    COUNT(positive) AS positive_count,
    COUNT(negative) AS negative_count,
    COUNT(publishers) AS publisher_count,
    COUNT(genres) AS genre_count
FROM steam_games;


-- 1.4 Check blank names and empty metadata arrays
SELECT
    SUM(CASE WHEN name = '' THEN 1 ELSE 0 END) AS missing_name,
    SUM(CASE WHEN ARRAY_LENGTH(publishers) = 0 THEN 1 ELSE 0 END) AS missing_publishers,
    SUM(CASE WHEN ARRAY_LENGTH(developers) = 0 THEN 1 ELSE 0 END) AS missing_developers,
    SUM(CASE WHEN ARRAY_LENGTH(genres) = 0 THEN 1 ELSE 0 END) AS missing_genres
FROM steam_games;


-- 1.5 Convert missing counts into percentages
SELECT
    ROUND(
        SUM(CASE WHEN name = '' THEN 1 ELSE 0 END)
        / COUNT(*) * 100,
        2
    ) AS name_missing_pct,
    ROUND(
        SUM(CASE WHEN ARRAY_LENGTH(publishers) = 0 THEN 1 ELSE 0 END)
        / COUNT(*) * 100,
        2
    ) AS publisher_missing_pct,
    ROUND(
        SUM(CASE WHEN ARRAY_LENGTH(developers) = 0 THEN 1 ELSE 0 END)
        / COUNT(*) * 100,
        2
    ) AS developer_missing_pct,
    ROUND(
        SUM(CASE WHEN ARRAY_LENGTH(genres) = 0 THEN 1 ELSE 0 END)
        / COUNT(*) * 100,
        2
    ) AS genre_missing_pct
FROM steam_games;


-- 1.6 Validate the price range
SELECT
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    AVG(price) AS avg_price
FROM steam_games;


-- 1.7 Inspect the highest-priced titles instead of automatically
-- treating extreme prices as data errors
SELECT
    name,
    price
FROM steam_games
ORDER BY price DESC
LIMIT 10;


-- ============================================================
-- SECTION 2 — PRICE SEGMENTATION
-- ============================================================

-- 2.1 Explore the distribution of titles across price tiers
SELECT
    CASE
        WHEN price = 0 THEN 'Free'
        WHEN price < 2 THEN 'Micro-Priced'
        WHEN price < 5 THEN 'Entry-Level'
        WHEN price < 10 THEN 'Budget'
        WHEN price < 25 THEN 'Value'
        WHEN price < 50 THEN 'Mid-Tier'
        WHEN price < 70 THEN 'Premium'
        WHEN price < 100 THEN 'High-Priced'
        ELSE 'Outliers'
    END AS price_tier,
    COUNT(*) AS game_count
FROM steam_games
GROUP BY price_tier
ORDER BY game_count DESC;


-- 2.2 Check the most common exact paid price points
SELECT
    price,
    COUNT(*) AS game_count
FROM steam_games
WHERE price > 0
GROUP BY price
ORDER BY game_count DESC
LIMIT 25;


-- 2.3 Create a reusable price-tier view for later analysis
CREATE OR REPLACE VIEW steam_price_data AS
SELECT
    *,
    CASE
        WHEN price = 0 THEN 'Free'
        WHEN price < 2 THEN 'Micro-Priced'
        WHEN price < 5 THEN 'Entry-Level'
        WHEN price < 10 THEN 'Budget'
        WHEN price < 25 THEN 'Value'
        WHEN price < 50 THEN 'Mid-Tier'
        WHEN price < 70 THEN 'Premium'
        WHEN price < 100 THEN 'High-Priced'
        ELSE 'Outliers'
    END AS price_tier
FROM steam_games;


-- ============================================================
-- SECTION 3 — PRICE-TIER PERFORMANCE ANALYSIS
-- ============================================================

-- 3.1 Broad price-tier scorecard
-- Includes multiple CCU thresholds so performance is not judged
-- only by averages that may be distorted by blockbuster titles.
SELECT
    price_tier,
    COUNT(*) AS game_count,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(
        SUM(CASE WHEN peak_ccu >= 10 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS ccu_10_plus_rate,
    ROUND(
        SUM(CASE WHEN peak_ccu >= 100 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS ccu_100_plus_rate,
    ROUND(
        SUM(CASE WHEN peak_ccu >= 1000 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS ccu_1000_plus_rate,
    ROUND(
        SUM(CASE WHEN peak_ccu > 0 THEN 1 ELSE 0 END)
        / COUNT(*) * 100,
        2
    ) AS active_games_rate,
    ROUND(AVG(peak_ccu), 2) AS avg_ccu,
    MAX(peak_ccu) AS max_ccu,
    MEDIAN(
        CASE
            WHEN peak_ccu > 0 THEN peak_ccu
            ELSE NULL
        END
    ) AS med_ccu,
    ROUND(AVG(average_playtime_forever), 2) AS avg_playtime_minutes,
    ROUND(
        SUM(positive)
        / (SUM(positive) + SUM(negative)) * 100,
        2
    ) AS positive_review_rate
FROM steam_price_data
GROUP BY price_tier
ORDER BY avg_price;


-- 3.2 Playtime distribution and threshold analysis
SELECT
    price_tier,
    ROUND(AVG(average_playtime_forever), 2) AS avg_playtime,
    ROUND(
        SUM(CASE WHEN average_playtime_forever >= 60 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS playtime_1h_plus_rate,
    ROUND(
        SUM(CASE WHEN average_playtime_forever >= 300 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS playtime_5h_plus_rate,
    ROUND(
        SUM(CASE WHEN average_playtime_forever >= 600 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS playtime_10h_plus_rate,
    MEDIAN(average_playtime_forever) AS median_playtime,
    MIN(average_playtime_forever) AS min_playtime,
    MAX(average_playtime_forever) AS max_playtime
FROM steam_price_data
GROUP BY price_tier
ORDER BY avg_playtime;


-- 3.3 Review-volume distribution and threshold analysis
SELECT
    price_tier,
    ROUND(AVG(positive + negative), 2) AS avg_reviews,
    MEDIAN(positive + negative) AS median_reviews,
    MIN(positive + negative) AS min_reviews,
    MAX(positive + negative) AS max_reviews,
    ROUND(
        SUM(CASE WHEN positive + negative >= 10 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS reviews_10_plus_rate,
    ROUND(
        SUM(CASE WHEN positive + negative >= 100 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS reviews_100_plus_rate,
    ROUND(
        SUM(CASE WHEN positive + negative >= 1000 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS reviews_1000_plus_rate
FROM steam_price_data
GROUP BY price_tier
ORDER BY reviews_100_plus_rate;


-- 3.4 Robustness check:
-- Recalculate satisfaction using only titles with at least 100 reviews
SELECT
    price_tier,
    COUNT(*) AS games_with_100_plus_reviews,
    ROUND(
        SUM(positive) * 100.0
        / (SUM(positive) + SUM(negative)),
        2
    ) AS positive_review_rate_100_plus
FROM steam_price_data
WHERE positive + negative >= 100
GROUP BY price_tier
ORDER BY positive_review_rate_100_plus DESC;


-- ============================================================
-- SECTION 4 — $5 PRICE-BUCKET ANALYSIS
-- ============================================================

-- 4.1 Review satisfaction by $5 price bucket
SELECT
    FLOOR(price / 5) * 5 AS price_bucket,
    COUNT(*) AS game_count,
    ROUND(
        SUM(positive) * 100.0
        / (SUM(positive) + SUM(negative)),
        2
    ) AS positive_review_rate
FROM steam_games
WHERE positive + negative >= 100
  AND price < 100
GROUP BY price_bucket
ORDER BY price_bucket;


-- 4.2 Player activity by $5 price bucket
SELECT
    FLOOR(price / 5) * 5 AS price_bucket,
    COUNT(*) AS game_count,
    ROUND(
        SUM(CASE WHEN peak_ccu > 0 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS active_games_rate,
    ROUND(
        SUM(CASE WHEN peak_ccu >= 100 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS ccu_100_plus_rate,
    ROUND(
        SUM(CASE WHEN peak_ccu >= 1000 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS ccu_1000_plus_rate
FROM steam_games
WHERE price < 100
GROUP BY price_bucket
ORDER BY price_bucket;


-- 4.3 Playtime by $5 price bucket
SELECT
    FLOOR(price / 5) * 5 AS price_bucket,
    COUNT(*) AS game_count,
    ROUND(
        SUM(CASE WHEN average_playtime_forever >= 60 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS playtime_1h_plus_rate,
    ROUND(
        SUM(CASE WHEN average_playtime_forever >= 300 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS playtime_5h_plus_rate,
    ROUND(
        SUM(CASE WHEN average_playtime_forever >= 600 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS playtime_10h_plus_rate
FROM steam_games
WHERE price < 100
GROUP BY price_bucket
ORDER BY price_bucket;


-- ============================================================
-- SECTION 5 — $50–$54.99 ANOMALY INVESTIGATION
-- ============================================================

-- 5.1 Inspect individual titles in the unusual $50–$54.99 bucket
SELECT
    name,
    price,
    peak_ccu,
    average_playtime_forever,
    positive,
    negative
FROM steam_games
WHERE price >= 50
  AND price < 55
ORDER BY average_playtime_forever DESC;


-- 5.2 Check exact prices inside the bucket
SELECT
    price,
    COUNT(*) AS game_count
FROM steam_games
WHERE price >= 50
  AND price < 55
GROUP BY price
ORDER BY game_count DESC;


-- 5.3 Check whether one publisher dominates the $54.99 cluster
SELECT
    publishers,
    COUNT(*) AS game_count
FROM steam_games
WHERE price = 54.99
GROUP BY publishers
ORDER BY game_count DESC
LIMIT 20;


-- 5.4 Check whether one developer dominates the $54.99 cluster
SELECT
    developers,
    COUNT(*) AS game_count
FROM steam_games
WHERE price = 54.99
GROUP BY developers
ORDER BY game_count DESC
LIMIT 20;


-- 5.5 Check the genre mix of the $54.99 cluster
SELECT
    genres,
    COUNT(*) AS game_count
FROM steam_games
WHERE price = 54.99
GROUP BY genres
ORDER BY game_count DESC
LIMIT 20;


-- 5.6 Broad Free vs Paid comparison
SELECT
    CASE
        WHEN price = 0 THEN 'Free'
        ELSE 'Paid'
    END AS pricing_model,
    COUNT(*) AS game_count,
    ROUND(
        SUM(CASE WHEN peak_ccu > 0 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS active_games_rate,
    ROUND(
        SUM(CASE WHEN peak_ccu >= 100 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS ccu_100_plus_rate,
    ROUND(
        SUM(CASE WHEN average_playtime_forever >= 60 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS playtime_1h_plus_rate,
    ROUND(
        SUM(positive) * 100.0
        / (SUM(positive) + SUM(negative)),
        2
    ) AS positive_review_rate
FROM steam_games
GROUP BY pricing_model;


-- ============================================================
-- SECTION 6 — GENRE MARKET ANALYSIS
-- ============================================================

-- 6.1 Preview how the genre array expands into rows
SELECT
    name,
    UNNEST(genres) AS genre
FROM steam_games
LIMIT 20;


-- 6.2 Measure market supply by genre
SELECT
    genre,
    COUNT(*) AS game_count
FROM steam_games,
UNNEST(genres) AS t(genre)
GROUP BY genre
ORDER BY game_count DESC;


-- 6.3 Compare genre-level activity and playtime
SELECT
    genre,
    COUNT(*) AS game_count,
    ROUND(
        SUM(CASE WHEN peak_ccu > 0 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS active_games_rate,
    ROUND(
        SUM(CASE WHEN peak_ccu >= 100 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS ccu_100_plus_rate,
    ROUND(
        SUM(CASE WHEN average_playtime_forever >= 60 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS playtime_1h_plus_rate
FROM steam_games,
UNNEST(genres) AS t(genre)
GROUP BY genre
ORDER BY game_count DESC;


-- 6.4 Compare genre satisfaction and review depth
SELECT
    genre,
    COUNT(*) AS game_count,
    ROUND(
        SUM(positive) * 100.0
        / (SUM(positive) + SUM(negative)),
        2
    ) AS positive_review_rate,
    ROUND(
        SUM(CASE WHEN positive + negative >= 100 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS reviews_100_plus_rate
FROM steam_games,
UNNEST(genres) AS t(genre)
GROUP BY genre
HAVING COUNT(*) >= 100
ORDER BY positive_review_rate DESC;


-- 6.5 Genre satisfaction robustness check:
-- restrict to titles with at least 100 reviews
SELECT
    genre,
    COUNT(*) AS games_with_100_plus_reviews,
    ROUND(
        SUM(positive) * 100.0
        / (SUM(positive) + SUM(negative)),
        2
    ) AS positive_review_rate_100_plus
FROM steam_games,
UNNEST(genres) AS t(genre)
WHERE positive + negative >= 100
GROUP BY genre
HAVING COUNT(*) >= 50
ORDER BY positive_review_rate_100_plus DESC;


-- 6.6 Final mainstream genre KPI table
SELECT
    genre,
    COUNT(*) AS game_count,
    ROUND(
        SUM(CASE WHEN peak_ccu >= 100 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS ccu_100_plus_rate,
    ROUND(
        SUM(CASE WHEN average_playtime_forever >= 60 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS playtime_1h_plus_rate,
    ROUND(
        SUM(positive) * 100.0
        / (SUM(positive) + SUM(negative)),
        2
    ) AS positive_review_rate
FROM steam_games,
UNNEST(genres) AS t(genre)
GROUP BY genre
HAVING COUNT(*) >= 1000
ORDER BY game_count DESC;


-- ============================================================
-- SECTION 7 — GENRE OPPORTUNITY RANKING
-- Multi-stage CTE + Window Functions
-- ============================================================

WITH genre_summary AS (
    SELECT
        genre,
        COUNT(*) AS game_count,
        ROUND(
            SUM(CASE WHEN peak_ccu >= 100 THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*),
            2
        ) AS ccu_100_plus_rate,
        ROUND(
            SUM(CASE WHEN average_playtime_forever >= 60 THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*),
            2
        ) AS playtime_1h_plus_rate,
        ROUND(
            SUM(positive) * 100.0
            / (SUM(positive) + SUM(negative)),
            2
        ) AS positive_review_rate
    FROM steam_games,
    UNNEST(genres) AS t(genre)
    WHERE genre NOT IN (
        'Utilities',
        'Free To Play',
        'Early Access'
    )
    GROUP BY genre
    HAVING COUNT(*) >= 1000
),
genre_rankings AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            ORDER BY game_count
        ) AS competition_rank,
        DENSE_RANK() OVER (
            ORDER BY ccu_100_plus_rate DESC
        ) AS engagement_rank,
        DENSE_RANK() OVER (
            ORDER BY playtime_1h_plus_rate DESC
        ) AS playtime_rank,
        DENSE_RANK() OVER (
            ORDER BY positive_review_rate DESC
        ) AS satisfaction_rank
    FROM genre_summary
),
genre_opportunity AS (
    SELECT
        *,
        competition_rank
        + engagement_rank
        + playtime_rank
        + satisfaction_rank AS opportunity_score
    FROM genre_rankings
)
SELECT *
FROM genre_opportunity
ORDER BY opportunity_score;


-- ============================================================
-- SECTION 8 — PUBLISHER PORTFOLIO ANALYSIS
-- ============================================================

-- 8.1 Publisher-level portfolio summary
SELECT
    publisher,
    COUNT(*) AS game_count,
    ROUND(AVG(price), 2) AS avg_price,
    SUM(positive + negative) AS total_reviews,
    SUM(
        CASE
            WHEN peak_ccu >= 100 THEN 1
            ELSE 0
        END
    ) AS games_100_plus_ccu,
    ROUND(
        SUM(positive) * 100.0
        / (SUM(positive) + SUM(negative)),
        2
    ) AS positive_review_rate
FROM steam_games,
UNNEST(publishers) AS t(publisher)
GROUP BY publisher
HAVING COUNT(*) >= 10
ORDER BY total_reviews DESC;


-- 8.2 Identify the highest-peak-CCU title for each publisher
WITH ranked_games AS (
    SELECT
        publisher,
        name,
        peak_ccu,
        positive,
        negative,
        ROW_NUMBER() OVER (
            PARTITION BY publisher
            ORDER BY peak_ccu DESC
        ) AS rn
    FROM steam_games,
    UNNEST(publishers) AS t(publisher)
)
SELECT
    publisher,
    name,
    peak_ccu,
    positive,
    negative
FROM ranked_games
WHERE rn = 1
ORDER BY peak_ccu DESC;


-- ============================================================
-- SECTION 9 — GENRE × PRICE-TIER CROSS-SEGMENT ANALYSIS
-- ============================================================

-- 9.1 Compare supply and total review traction across
-- genre × price-tier combinations
SELECT
    genre,
    price_tier,
    COUNT(*) AS game_count,
    SUM(positive + negative) AS total_reviews,
    ROUND(AVG(price), 2) AS avg_price
FROM steam_price_data,
UNNEST(genres) AS t(genre)
WHERE genre NOT IN (
    'Utilities',
    'Free To Play',
    'Early Access',
    'Design & Illustration',
    'Animation & Modeling',
    'Video Production',
    'Education'
)
GROUP BY
    genre,
    price_tier
HAVING COUNT(*) >= 100
ORDER BY total_reviews DESC;


-- 9.2 Normalize traction by game count so large segments do not
-- automatically dominate because they contain more titles
SELECT
    genre,
    price_tier,
    COUNT(*) AS game_count,
    SUM(positive + negative) AS total_reviews,
    ROUND(
        SUM(positive + negative) * 1.0 / COUNT(*),
        0
    ) AS reviews_per_game
FROM steam_price_data,
UNNEST(genres) AS t(genre)
WHERE genre NOT IN (
    'Utilities',
    'Free To Play',
    'Early Access',
    'Design & Illustration',
    'Animation & Modeling',
    'Video Production',
    'Education'
)
GROUP BY
    genre,
    price_tier
HAVING COUNT(*) >= 100
ORDER BY reviews_per_game DESC;


-- ============================================================
-- END OF ANALYSIS
-- ============================================================
