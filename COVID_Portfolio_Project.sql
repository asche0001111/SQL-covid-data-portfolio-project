SELECT *
FROM Covid_Deaths
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT *
FROM Covid_Vaccinations
WHERE continent IS NOT NULL
ORDER BY 3,4

-- select data that i'm gonna use

SELECT [location], [date], [total_cases], [new_cases], [total_deaths], [population]
FROM Covid_Deaths
WHERE continent IS NOT NULL
order by 1,2

-- looking at total cases vs total deaths
--likelihood of dying of covid at any timeperiod 

SELECT [location], [date], [total_cases], [total_deaths], (CAST(total_deaths AS DECIMAL) / total_cases)*100 AS death_percentage
FROM Covid_Deaths
WHERE [location] LIKE '%states%' AND continent IS NOT NULL
order by 1,2

-- looking at total cases vs population
-- shows what percentage of population has gotten covid

SELECT [location], [date], [total_cases], [population], (CAST(total_cases AS DECIMAL) / population)*100 AS infected_percentage
FROM Covid_Deaths
WHERE [location] LIKE '%germany%' AND continent IS NOT NULL
order by 1,2

-- looking at countries with highest infection rate compared to population 

SELECT [location], MAX(total_cases) AS max_cases, [population], (CAST(MAX(total_cases) AS DECIMAL) / population)*100 AS max_infected_percentage
FROM Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY [location], [population]
order by max_infected_percentage DESC

-- looking at countries with highest death count compared to population

SELECT [location], MAX(total_deaths) AS total_deaths, [population], (CAST(MAX(total_deaths) AS DECIMAL) / population)*100 AS max_death_percentage
FROM Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY [location], [population]
order by total_deaths DESC

-- sorting by continents and income groupings

SELECT [location], MAX(population) AS population, MAX(total_deaths) AS total_deaths
FROM Covid_Deaths
WHERE continent IS NULL
GROUP BY [location]
order by total_deaths DESC

-- sorting by Asia

SELECT [continent], [location], MAX(population) AS population, MAX(total_deaths) AS total_deaths
FROM Covid_Deaths
WHERE continent = 'Asia'
GROUP BY [continent], [location]
order by total_deaths DESC

-- GLOBAL

SELECT 
    [location], 
    [date], 
    MAX(total_cases) AS max_cases,
    MAX(total_deaths) AS max_deaths,
    (CAST(MAX(total_deaths) AS DECIMAL) / MAX(total_cases)) * 100 AS death_percentage
FROM 
    Covid_Deaths
WHERE 
    continent IS NOT NULL
GROUP BY 
    [location], [date]
ORDER BY 
    [location], [date];

SELECT
    SUM(new_cases) AS total_cases,
    SUM(cast(new_deaths as int)) as total_deaths,
    SUM(cast(new_deaths as int))/CAST(SUM(new_cases) AS DECIMAL)*100 as death_percentage
FROM 
    Covid_Deaths
WHERE   
    continent IS NOT NULL;

--joining both tables

SELECT *
FROM Covid_Deaths AS Dea
JOIN Covid_Vaccinations AS Vac
    ON Dea.[location] = Vac.[location]
    AND Dea.[date] = Vac.[date]

-- lookong at total population vs vaccination

SELECT Dea.continent, Dea.[location], Dea.[date], Vac.new_vaccinations, 
SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY Dea.location ORDER BY Dea.[location], Dea.[date]) AS total_vaccinations_per_location
FROM Covid_Deaths AS Dea
JOIN Covid_Vaccinations AS Vac
    ON Dea.[location] = Vac.[location]
    AND Dea.[date] = Vac.[date]
WHERE Dea.continent IS NOT NULL
ORDER BY 2,3

-- calculating vaccinated percentage with CTE

WITH PopVsVac (continent, [location], [date], [population], new_vaccinations, total_vaccinations_per_location)
AS 
(
SELECT Dea.continent, Dea.[location], Dea.[date], Dea.population, Vac.new_vaccinations, 
SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY Dea.location ORDER BY Dea.[location], Dea.[date]) AS total_vaccinations_per_location
FROM Covid_Deaths AS Dea
JOIN Covid_Vaccinations AS Vac
    ON Dea.[location] = Vac.[location]
    AND Dea.[date] = Vac.[date]
WHERE Dea.continent IS NOT NULL
)
SELECT *, (total_vaccinations_per_location / population) * 100 AS vaccinated_percentage
FROM PopVsVac

-- doing the same but with a temp table

DROP TABLE IF EXISTS #vaccinated_percentage
CREATE TABLE #vaccinated_percentage 
(
    continent varchar(50),
    [location] varchar(50),
    [date] date,
    [population] bigint,
    new_vaccinations bigint,
    total_vaccinations_per_location bigint
)

INSERT INTO #vaccinated_percentage
SELECT Dea.continent, Dea.[location], Dea.[date], Dea.population, Vac.new_vaccinations, 
SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY Dea.location ORDER BY Dea.[location], Dea.[date]) AS total_vaccinations_per_location
FROM Covid_Deaths AS Dea
JOIN Covid_Vaccinations AS Vac
    ON Dea.[location] = Vac.[location]
    AND Dea.[date] = Vac.[date]
WHERE Dea.continent IS NOT NULL

SELECT *, (total_vaccinations_per_location / population) * 100 AS vaccinated_percentage
FROM #vaccinated_percentage

--creating a view to visualize data

CREATE VIEW vaccinated_percentage AS 
SELECT Dea.continent, Dea.[location], Dea.[date], Dea.population, Vac.new_vaccinations, 
SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY Dea.location ORDER BY Dea.[location], Dea.[date]) AS total_vaccinations_per_location
FROM Covid_Deaths AS Dea
JOIN Covid_Vaccinations AS Vac
    ON Dea.[location] = Vac.[location]
    AND Dea.[date] = Vac.[date]
WHERE Dea.continent IS NOT NULL

SELECT *
FROM vaccinated_percentage
