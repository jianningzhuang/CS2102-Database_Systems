------------------------------------------------------------------------
------------------------------------------------------------------------
--
-- CS2102 - ASSIGNMENT 1 (SQL)
--
------------------------------------------------------------------------
------------------------------------------------------------------------



DROP VIEW IF EXISTS student, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10;



------------------------------------------------------------------------
-- Replace the dummy values without Student ID & NUSNET ID
------------------------------------------------------------------------

DROP VIEW IF EXISTS student;
CREATE OR REPLACE VIEW student(student_id, nusnet_id) AS
 SELECT 'A0214561M', 'e0527277'
;






------------------------------------------------------------------------
-- Query Q1
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v1 (city_name) AS 
SELECT name AS city_name 
FROM Cities 
WHERE population > 10000000 AND capital = 'primary';





------------------------------------------------------------------------
-- Query Q2
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v2 (country_name, capital_count) AS 
SELECT n.name AS country_name, COUNT(DISTINCT c.name) AS capital_count 
FROM Countries n, Cities c 
WHERE n.iso2 = c.country_iso2 AND c.capital = 'primary' 
GROUP BY n.iso2 
HAVING COUNT(DISTINCT c.name) > 1;




------------------------------------------------------------------------
-- Query Q3
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v3 (country_name) AS 
SELECT n.name AS country_name 
FROM Countries n 
WHERE n.continent = 'Europe' 
AND (n.gdp/n.population) > (SELECT (n1.gdp/n1.population) AS gdp_per_capita 
			FROM Countries n1 
			WHERE n1.iso2 = 'SG');






------------------------------------------------------------------------
-- Query Q4
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v4 (country_name) AS 
(SELECT n.name AS country_name 
FROM Countries n, Cities c 
WHERE n.iso2 = c.country_iso2 
GROUP BY n.iso2 
HAVING COUNT(DISTINCT c.name) = 1) 
INTERSECT 
(SELECT n.name AS country_name 
FROM Countries n 
WHERE NOT EXISTS (SELECT 1 
		FROM Cities c 
		WHERE n.iso2 = c.country_iso2 
		AND c.capital IS DISTINCT FROM 'primary'));




------------------------------------------------------------------------
-- Query 5
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v5 (country_name, domestic_connections_count) AS  
SELECT n.name AS country_name, d.domestic_connections_count AS domestic_connections_count 
FROM Countries n, 
(SELECT a1.country_iso2 AS country_iso2, COUNT(*) AS domestic_connections_count 
FROM Connections c, Airports a1, Airports a2, Countries n 
WHERE c.from_code = a1.code AND c.to_code = a2.code 
AND a1.country_iso2 = a2.country_iso2 AND a1.country_iso2 = n.iso2 
GROUP BY a1.country_iso2 
HAVING COUNT(*) > 100) AS d 
WHERE n.iso2 = d.country_iso2 
ORDER BY d.domestic_connections_count DESC;





------------------------------------------------------------------------
-- Query Q6
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v6 (country_name1, country_name2) AS 
SELECT n1.name AS country_name1, n2.name AS country_name2 
FROM Borders b, Countries n1, Countries n2 
WHERE b.country1_iso2 = n1.iso2 AND b.country2_iso2 = n2.iso2 
AND n1.continent = 'Asia' AND n2.continent = 'Asia' 
AND n1.population < n2.population;





------------------------------------------------------------------------
-- Query Q7
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v7 (country_name) AS 
SELECT n.name AS country_name 
FROM Countries n 
WHERE n.continent = 'Asia' 
AND NOT EXISTS (SELECT 1 
		FROM Visited v 
		WHERE n.iso2 = v.iso2 
		AND (v.user_id = (SELECT u.user_id FROM Users u WHERE u.name = 'Marie') OR 
			v.user_id = (SELECT u.user_id FROM Users u WHERE u.name = 'Bill') OR 
			v.user_id = (SELECT u.user_id FROM Users u WHERE u.name = 'Sam') OR 
			v.user_id = (SELECT u.user_id FROM Users u WHERE u.name = 'Sarah')));






------------------------------------------------------------------------
-- Query Q8
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v8 (city_name) AS
(SELECT DISTINCT c.name AS city_name 
FROM Routes r, Airports a, Cities c 
WHERE r.from_code = 'SIN' AND r.airline_code = 'SQ' 
AND r.to_code = a.code AND a.city = c.name AND a.country_iso2 = 'US') 
UNION 
(SELECT DISTINCT c.name AS city_name 
FROM Routes r1, Routes r2, Airports a1, Airports a2, Cities c, Countries n 
WHERE r1.from_code = 'SIN' AND r1.airline_code = 'SQ' AND r2.airline_code = 'SQ' 
AND r1.to_code = a1.code AND a1.country_iso2 = n.iso2 AND n.continent = 'Europe' 
AND r1.to_code = r2.from_code AND r2.to_code = a2.code AND a2.city = c.name AND a2.country_iso2 = 'US');





------------------------------------------------------------------------
-- Query Q9
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v9 (country_name, crossing_count) AS 
WITH RECURSIVE border_path AS ( 
SELECT country1_iso2, country2_iso2, 1 AS crossings 
FROM Borders 
WHERE country1_iso2 = 'MY' 
UNION ALL 
SELECT b.country1_iso2, b.country2_iso2, p.crossings+1 
FROM border_path p, Borders b 
WHERE p.country2_iso2 = b.country1_iso2 
AND p.crossings <= 9 
) 
SELECT n.name AS country_name, MIN(bp.crossings) AS crossing_count    
FROM border_path bp, Countries n 
WHERE bp.country2_iso2 = n.iso2 AND n.continent = 'Africa' 
GROUP BY n.name;




------------------------------------------------------------------------
-- Query Q10
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v10 (airport_name) AS 
SELECT a1.name AS airport_name 
FROM Airports a1 
WHERE NOT EXISTS (SELECT continent FROM Countries GROUP BY continent 
		EXCEPT 
		SELECT n.continent 
		FROM Countries n, Airports a2, Connections c 
		WHERE c.from_code = a1.code AND c.to_code = a2.code AND a2.country_iso2 = n.iso2 
		GROUP BY n.continent);


