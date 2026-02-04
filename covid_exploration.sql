-- Covid Deaths and Vaccinations Data Exploration


-- CREATE TABLES

DROP TABLE IF EXISTS covid_deaths;
CREATE TABLE covid_deaths (
	iso_code VARCHAR(50),
	continent VARCHAR(50),
	location VARCHAR(50),
	date VARCHAR(50),
	population BIGINT,
	total_cases	INT,
	new_cases INT,
	new_cases_smoothed FLOAT,
	total_deaths INT,
	new_deaths INT,
	new_deaths_smoothed FLOAT,
	total_cases_per_million	FLOAT,
	new_cases_per_million FLOAT,
	new_cases_smoothed_per_million FLOAT,
	total_deaths_per_million FLOAT,
	new_deaths_per_million FLOAT,
	new_deaths_smoothed_per_million FLOAT,
	reproduction_rate FLOAT,
	icu_patients INT,
	icu_patients_per_million FLOAT,
	hosp_patients INT,
	hosp_patients_per_million FLOAT,
	weekly_icu_admissions FLOAT,
	weekly_icu_admissions_per_million FLOAT,
	weekly_hosp_admissions FLOAT,
	weekly_hosp_admissions_per_million FLOAT

);

DROP TABLE IF EXISTS covid_vacc;
CREATE TABLE covid_vacc (
	iso_code VARCHAR (50),
	continent VARCHAR (50),
	location VARCHAR (50),
	date VARCHAR(50),
	new_tests INT,
	total_tests INT, 
	total_tests_per_thousand FLOAT,
	new_tests_per_thousand FLOAT,
	new_tests_smoothed INT,
	new_tests_smoothed_per_thousand FLOAT,
	positive_rate FLOAT,
	tests_per_case FLOAT,
	tests_units VARCHAR(50),
	total_vaccinations INT,
	people_vaccinated INT, 
	people_fully_vaccinated INT,
	new_vaccinations INT, 
	new_vaccinations_smoothed INT,
	total_vaccinations_per_hundred FLOAT,
	people_vaccinated_per_hundred FLOAT, 
	people_fully_vaccinated_per_hundred FLOAT,
	new_vaccinations_smoothed_per_million INT,
	stringency_index FLOAT,
	population_density FLOAT,
	median_age FLOAT,
	aged_65_older FLOAT,
	aged_70_older FLOAT,
	gdp_per_capita FLOAT,
	extreme_poverty FLOAT,
	cardiovasc_death_rate FLOAT,
	diabetes_prevalence FLOAT,
	female_smokers FLOAT,
	male_smokers FLOAT,
	handwashing_facilities FLOAT,
	hospital_beds_per_thousand FLOAT,
	life_expectancy FLOAT,
	human_development_index FLOAT
);


-- Convert the date column from VARCHAR to DATE
ALTER TABLE covid_deaths
ADD new_date DATE;

UPDATE covid_deaths
SET new_date = STR_TO_DATE(date, '%m/%d/%Y');

ALTER TABLE covid_deaths
DROP date;

ALTER TABLE covid_deaths
RENAME COLUMN new_date TO date;

-- ---------------------------

ALTER TABLE covid_vacc
ADD new_date DATE;

UPDATE covid_vacc
SET new_date = STR_TO_DATE(date, '%m/%d/%Y');

ALTER TABLE covid_vacc
DROP date;

ALTER TABLE covid_vacc
RENAME COLUMN new_date TO date;


-- DATA EXPLORATION

-- Total Cases VS Total Deaths
-- What is the percentage of covid deaths?
SELECT location, date, total_cases, total_deaths, 
		(CAST(total_deaths AS FLOAT)/total_cases) * 100 AS death_percentage
FROM covid_deaths
ORDER BY location, date;

-- In the U.S.?
SELECT location, date, total_cases, total_deaths, 
		(CAST(total_deaths AS FLOAT)/total_cases) * 100 AS death_percentage
FROM covid_deaths
WHERE location = 'United States'
ORDER BY location, date;


-- Total Cases VS Population
-- What percent of the population has Covid?
SELECT location, date, population, total_cases, 
		(CAST(total_cases AS FLOAT)/population) * 100 AS covid_percentage
FROM covid_deaths
ORDER BY location, date;

-- In the U.S.?
SELECT location, date, population, total_cases, 
		(CAST(total_cases AS FLOAT)/population) * 100 AS covid_percentage
FROM covid_deaths
WHERE location = 'United States'
ORDER BY location, date;

-- Countries with highest infection rate compared to population:
WITH infected_percent
AS (
	SELECT location, population, MAX(total_cases) AS infectionCount, 
			(CAST(MAX(total_cases) AS FLOAT)/population) * 100 AS covid_percentage
	FROM covid_deaths
	GROUP BY location, population
	)
SELECT *
FROM infected_percent
WHERE covid_percentage IS NOT NULL
ORDER BY covid_percentage DESC;


-- Total Deaths VS Population
-- Countries with highest death count per population:
WITH death_count
AS (
	SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
	FROM covid_deaths
	WHERE continent IS NOT NULL
	GROUP BY location
	)
SELECT *
FROM death_count
WHERE TotalDeathCount IS NOT NULL
ORDER BY TotalDeathCount DESC;

-- Death count by continent
WITH death_count
AS (
	SELECT continent, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
	FROM covid_deaths
	WHERE continent IS NOT NULL
	GROUP BY continent
	)
SELECT *
FROM death_count
WHERE TotalDeathCount IS NOT NULL
ORDER BY TotalDeathCount DESC;


-- GLOBAL NUMBERS

-- Death percentage per day
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS UNSIGNED)) AS total_deaths,
		(SUM(CAST(new_deaths AS FLOAT))/SUM(new_cases)) * 100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date, total_cases;

-- Total death percentage
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS UNSIGNED)) AS total_deaths,
		(SUM(CAST(new_deaths AS FLOAT))/SUM(new_cases)) * 100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL;

-- Total Population VS Vaccinations
WITH PopVSVacc
AS (
	SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations,
			SUM(CAST(vacc.new_vaccinations AS UNSIGNED)) 
			OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS people_vaccinated,
			CAST(people_vaccinated AS FLOAT) / population * 100 AS percent_vaccinated
	FROM covid_deaths dea
	JOIN covid_vacc vacc
		ON dea.location = vacc.location 
		AND dea.date = vacc.date
	WHERE dea.continent IS NOT NULL
	)
SELECT *
FROM PopVSVacc;


-- TEMP TABLE

DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TABLE PercentPopulationVaccinated
(
continent VARCHAR(50),
location VARCHAR(50),
date date,
population numeric,
new_vaccinations numeric,
rollingPeopleVaccinated numeric
);

INSERT INTO  PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations,
		SUM(CAST(vacc.new_vaccinations AS UNSIGNED)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS people_vaccinated
FROM covid_deaths dea
JOIN covid_vacc vacc
	ON dea.location = vacc.location 
	AND dea.date = vacc.date;

SELECT *
FROM PercentPopulationVaccinated;


-- VIEW
-- Creating view to store data for visualizations
CREATE VIEW PercentPopulationVacc as 
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations,
		SUM(CAST(vacc.new_vaccinations AS UNSIGNED)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS people_vaccinated
FROM covid_deaths dea
JOIN covid_vacc vacc
	ON dea.location = vacc.location 
	AND dea.date = vacc.date
WHERE dea.continent IS NOT NULL;