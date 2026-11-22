# steam-game-market-analysis

# Project Overview

This project analyzes a Steam games dataset with 124,146 titles using SQL in MotherDuck / DuckDB.

I created this project to practice using SQL for a larger analysis instead of only solving individual SQL questions. I focused on how game price, genre, publisher, player activity, playtime, and reviews differ across the Steam catalog.

The project starts with data quality checks and exploratory analysis, then moves into pricing segmentation, genre analysis, publisher portfolio analysis, and cross-segment comparisons.


# Dataset

Source: Steam Games Dataset by FronkonGames on Hugging Face

Dataset link:
https://huggingface.co/datasets/FronkonGames/steam-games-dataset

The dataset contains information such as: 
Game name,
App ID,
Release date
Price
Peak concurrent users (peak_ccu)
Average playtime
Positive and negative reviews
Publishers
Developers
Genres

The original dataset contains 124,146 rows.



# Tools

SQL
MotherDuck
DuckDB
This project is intentionally focused on SQL rather than Python or visualization tools.



# SQL Skills Used

Some of the main SQL techniques used in this project include:
SELECT, WHERE, and ORDER BY
GROUP BY and HAVING
Aggregate functions such as COUNT, SUM, AVG, MIN, MAX, and MEDIAN
CASE WHEN
Conditional aggregation
CREATE VIEW
UNNEST()
Common Table Expressions (CTEs)
Multi-stage CTEs
Window functions
ROW_NUMBER()
DENSE_RANK()
PARTITION BY
Multi-column grouping



# Analysis

1. Data Understanding and Quality Checks
I first inspected the table structure and checked the main columns used in the analysis.
I checked:
Total number of records
Missing values
Blank game names
Empty publisher, developer, and genre arrays
Minimum, maximum, and average prices
Extremely high-priced titles
There were very few missing game names, but around 7% of the records had missing publisher, developer, or genre information.
I also found prices ranging from free games to titles priced close to $1,000. Instead of automatically removing high prices as errors, I kept them and investigated them separately.



2. Price Segmentation

I created several price groups to make games at different price levels easier to compare:
Free
Micro-Priced
Entry-Level
Budget
Value
Mid-Tier
Premium
High-Priced
Outliers

I then created a reusable SQL view called steam_price_data that adds the price_tier column to the original data.

This view is used throughout the rest of the project.



3. Price-Tier Performance

I compared price tiers using several types of performance measures:
Percentage of games reaching 10+, 100+, and 1,000+ peak concurrent users
Percentage of games with any recorded player activity
Average and median peak CCU
Average playtime
Positive review rate

One important part of this analysis was realizing that average values could be heavily affected by a small number of very successful games.
Because of this, I also used threshold-based measures such as the percentage of games reaching at least 100 peak concurrent users.

For example, the Mid-Tier segment showed stronger player activity than many lower-priced segments, while very high-priced and outlier titles generally showed much lower activity.

4. Playtime and Review Analysis

I also compared average playtime and review volume across price tiers.

For playtime, I calculated the percentage of games reaching:
1+ hour
5+ hours
10+ hours

For reviews, I calculated the percentage of games receiving:
10+ reviews
100+ reviews
1,000+ reviews

I also recalculated positive review rates using only games with at least 100 reviews.
This was useful because games with only a few reviews can have very high or very low ratings that are not very reliable.

5. Price-Bucket Investigation

In addition to the broader price tiers, I grouped games into $5 price buckets.
I compared these buckets using:
Player activity
Playtime
Review satisfaction
During this analysis, the $50–$54.99 range looked unusual.

I investigated the titles in this group and found that most of the games in the bucket were priced at exactly $54.99.
I then checked publishers, developers, and genres to see whether one company or category was responsible for the pattern.
The result suggested that the unusual performance was mainly caused by the mix of titles in the bucket rather than price alone.


6. Genre Market Analysis
The genres column contains arrays, so I used UNNEST() to convert each game's genre list into separate rows.
I then compared genres using:
Number of games
Player activity
Percentage reaching 100+ peak CCU
Percentage reaching at least 1 hour of average playtime
Positive review rate

To avoid comparing very small categories, I focused the main analysis on genres with at least 1,000 titles.



7. Genre Opportunity Ranking

I used multiple CTEs and DENSE_RANK() window functions to create a simple genre ranking.
Each genre was ranked using four dimensions:
Competition
Player engagement
Playtime
Player satisfaction
The four ranks were combined into an opportunity_score.

This is only an exploratory ranking rather than a predictive model, but it helped me practice using multi-stage CTEs and window functions for a business-style analysis.



8. Publisher Portfolio Analysis

I also analyzed publishers as portfolios instead of looking only at individual games.
For each publisher, I calculated:
Number of games
Average price
Total reviews
Number of games reaching 100+ peak CCU
Positive review rate

I then used:

ROW_NUMBER() OVER (PARTITION BY publisher ORDER BY peak_ccu DESC) to identify the highest-peak-CCU title for each publisher.
This is a common SQL pattern for finding the top record within each group.



9. Genre × Price Tier Analysis

The final part of the project combines genre and price tier.
I grouped games by both:
genre and price_tier
and compared:
Number of games
Total reviews
Average price
Reviews per game
Using reviews per game helped make the comparison more balanced because some market segments contain far more titles than others.

Some strong combinations included:
Action × Mid-Tier: about 17.3K reviews per game
Massively Multiplayer × Value: about 15.3K reviews per game
RPG × Mid-Tier: about 13.8K reviews per game
Strategy × Mid-Tier: about 10.4K reviews per game
In comparison, some very low-priced segments had a large number of games but much lower review traction per title.

Selected Results

I plan to include a few shortened result tables here instead of screenshots of every SQL output.
Price-Tier Performance
A shortened table will show the main price tiers and important KPIs such as:
Game count
Average price
100+ peak CCU rate
1+ hour playtime rate
Positive review rate
Genre Opportunity Ranking
A second table will show the highest-ranked mainstream genres using the combined opportunity score.
Genre × Price Tier Performance

A final table will highlight several genre and price combinations with strong review traction per game.
The complete queries and analysis are available in steam_game_market_analysis.sql.
Key Takeaways



# A few things stood out during the project:
Steam performance data is highly skewed, so averages alone can be misleading.
Mid-priced games performed well across several engagement and traction measures.
Large numbers of low-priced games do not necessarily translate into strong performance per title.
Genre and price together provide more useful information than looking at either dimension alone.
SQL can be used not only to retrieve data, but also to build KPIs, investigate unusual results, rank groups, and perform multi-step analysis.
