/*
World happiness report data exploration

Skills used: Joins, CTE's, Temp Tables, Window Function, Aggregation Function, Creating View, Conditional Expression

*/


SELECT * FROM report_all_year

-- Avg world life ladder score each year

SELECT year, ROUND(AVG(ladder_score), 2) AS avg_ladder_score
FROM report_all_year
GROUP BY (year)
ORDER BY year


-- Avg life ladder score for each region every year

SELECT regional, year, ROUND(AVG(report_all_year.ladder_score), 2) as avg_ladder_score
FROM report_all_year
RIGHT JOIN report2021
ON report_all_year.country = report2021.country
GROUP BY regional, year
ORDER BY regional, year


-- Avg life ladder score for each country

SELECT  country, ROUND(AVG(ladder_score), 2) AS avg_ladder_score
FROM report_all_year
GROUP BY country
ORDER BY ROUND(AVG(ladder_score), 2) DESC


--Avg life ladder score for each country every year

--Create CTE object
WITH country_ladder_score AS(
SELECT  country, year, ROUND(AVG(ladder_score), 2) AS avg_ladder_score
FROM report_all_year
GROUP BY country, year
)
--Add ranking column
SELECT *,
rank() OVER (PARTITION BY year ORDER BY avg_ladder_score DESC)
FROM country_ladder_score


--Well being index each region every year

--Create table
CREATE TABLE region_ladder_score(
	regional VARCHAR(50),
	year SMALLINT,
	avg_ladder_score NUMERIC
)
--Make a query to calculate avg ladder score for each region and insert into new table
INSERT INTO region_ladder_score
SELECT * FROM (
SELECT regional, year, ROUND(AVG(report_all_year.ladder_score), 2) AS avg_ladder_score
FROM report_all_year
RIGHT JOIN report2021
ON report_all_year.country = report2021.country
GROUP BY regional, year
ORDER BY year, ROUND(AVG(report_all_year.ladder_score), 2) DESC
)
--Add ranking column
SELECT *,
rank() OVER (PARTITION BY year ORDER BY avg_ladder_score DESC)
FROM region_ladder_score


--Well being index each country every year

SELECT country, year, ladder_score, 
(COALESCE(social_support, 0) + COALESCE(health_expectation, 0) + COALESCE(choice_freedom, 2) 
 + COALESCE(generosity, 2) + COALESCE(positive_affect, 2)) AS well_being_index
FROM report_all_year
ORDER BY country, year


--Changes in ladder score for each country through the year

SELECT country, year, ladder_score,
ladder_score - LAG(ladder_score) OVER (PARTITION BY country ORDER BY year) AS lag_ladder_score
FROM report_all_year


--Relative Score for each factor for every coutnry each year

SELECT country, year,
ROUND(log_gdp / MAX(log_gdp) OVER (PARTITION BY year), 2) AS relative_log_gdp,
ROUND(social_support / MAX(social_support) OVER (PARTITION BY year), 2) AS relative_social_support,
ROUND(health_expectation / MAX(health_expectation) OVER (PARTITION BY year), 2) AS relative_health_expectation,
ROUND(choice_freedom / MAX(choice_freedom) OVER (PARTITION BY year), 2) AS relative_choice_freedom,
ROUND(generosity / MAX(generosity) OVER (PARTITION BY year), 2) AS relative_generosity,
ROUND(corruption_perception / MAX(corruption_perception) OVER (PARTITION BY year), 2) AS relative_corruption_perception,
ROUND(positive_affect / MAX(positive_affect) OVER (PARTITION BY year), 2) AS relative_positive_affect,
ROUND(negative_affect / MAX(negative_affect) OVER (PARTITION BY year), 2) AS relative_negative_affect,
ladder_score
FROM report_all_year


--Ratio of positive and negative effect on ladder score

SELECT country, year, ladder_score,
ROUND((positive_affect/negative_affect), 2) AS positive_negative_ratio,
RANK() OVER(PARTITION BY year ORDER BY ladder_score)
FROM report_all_year
WHERE ROUND((positive_affect/negative_affect), 2) NOTNULL



---Preparing data for later visualization

CREATE VIEW table2 AS
WITH table1 AS(
SELECT country, 
	ROUND(AVG(ladder_score), 2) AS avg_ladder_score,
	ROUND(AVG(log_gdp), 2) AS avg_log_gdp,
	ROUND(AVG(social_support), 2) AS avg_social_support,
	ROUND(AVG(health_expectation), 2) AS avg_health_expectation,
	ROUND(AVG(choice_freedom), 2) AS avg_choice_freedom,
	ROUND(AVG(generosity), 2) AS avg_generosity,
	ROUND(AVG(corruption_perception), 2) AS avg_corruption_perception
FROM report_all_year
GROUP BY country
ORDER BY ROUND(AVG(report_all_year.ladder_score), 2) DESC
)
SELECT country, avg_ladder_score, avg_log_gdp, avg_social_support, avg_health_expectation, avg_choice_freedom, avg_generosity, avg_corruption_perception, 
CASE WHEN avg_ladder_score BETWEEN 3 AND 4.5 THEN 'Low'
WHEN avg_ladder_score BETWEEN 4.5 AND 6 THEN 'Medium'
WHEN avg_ladder_score BETWEEN 6 AND 8 THEN 'High' END AS ladder_rank
FROM table1

SELECT country, avg_ladder_score, ladder_rank 
FROM table2

SELECT ROUND(AVG(avg_log_gdp), 2) AS gdp, ladder_rank 
FROM table2
GROUP BY ladder_rank

SELECT ROUND(AVG(avg_social_support), 2) AS social_support, ladder_rank 
FROM table2
GROUP BY ladder_rank

SELECT ROUND(AVG(avg_health_expectation), 2) AS health_expectation, ladder_rank 
FROM table2
GROUP BY ladder_rank

SELECT ROUND(AVG(avg_choice_freedom), 2) AS choice_freedom, ladder_rank 
FROM table2
GROUP BY ladder_rank

SELECT ROUND(AVG(avg_generosity), 2) AS generosity, ladder_rank 
FROM table2
GROUP BY ladder_rank

SELECT ROUND(AVG(avg_corruption_perception), 2) AS corruption_perception, ladder_rank 
FROM table2
GROUP BY ladder_rank



