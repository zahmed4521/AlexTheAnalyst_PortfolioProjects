-- SQL Queries for Covid Exploration Tableau Visualization

-- 1. 
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS UNSIGNED)) AS total_deaths,
		SUM(CAST(new_deaths AS FLOAT)) / SUM(New_Cases) * 100 AS DeathPercentage
FROM covid_deaths
WHERE continent IS NOT NULL 
ORDER BY 1, 2;


-- 2. 
-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe
SELECT location, SUM(CAST(new_deaths AS UNSIGNED)) AS TotalDeathCount
FROM covid_deaths
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- 3.
SELECT location, population, COALESCE(MAX(total_cases), 0) AS HighestInfectionCount,  
COALESCE(MAX((CAST(total_cases AS FLOAT) / population)), 0) * 100 AS PercentPopulationInfected
FROM covid_deaths
GROUP BY location, population
ORDER BY PercentPopulationInfected desc;


-- 4.
SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount,
		COALESCE(MAX((CAST(total_cases AS FLOAT) / population)), 0) * 100 AS PercentPopulationInfected
FROM covid_deaths
GROUP BY location, population, date
ORDER BY PercentPopulationInfected desc;