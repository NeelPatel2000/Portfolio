USE PortfolioProject;

SELECT * FROM Covid_Deaths6
WHERE continent is not null
ORDER BY 3,4

--SELECT * FROM Covid_Vaccinations6
--ORDER BY 3,4;

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Covid_Deaths6
ORDER BY 1,2

-- LOOKING AT THE TOTAL CASES VS TOTAL DEATHS:
-- SHOWS THE LIKELIHOOD OF DYING IF YOU CONTRACT COVID IN YOUR COUNTRY  

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..Covid_Deaths6
WHERE LOCATION LIKE '%STATES%'
ORDER BY 1,2


--LOOKING AT THE TOTAL CASES VS THE POPULATION: 
--SHOWS WHAT PERCENTAGE POPULATION GOT COVID

SELECT location, date, population, total_cases, (total_cases/population) * 100 as PercentPopulationInfected
FROM PortfolioProject..Covid_Deaths6
--WHERE LOCATION LIKE '%states%'
ORDER BY 1,2

-- LOOKING AT COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO POPULATION;

SELECT location, population, MAX(total_cases) AS HighestinfectionCount, MAX((total_cases/population)) * 100 as PercentPopulationInfected
FROM PortfolioProject..Covid_Deaths6
--WHERE location LIKE '%states%'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


--SHOWING THE COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION;

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..Covid_Deaths6
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- LET'S BREAK THINGS BY CONTINENT
--SHOWING THE CONTINENTS WITH THE HIGHEST DEATH COUNT; 
SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..Covid_Deaths6
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

--GLOBAL NUMBERS

SELECT date, SUM(new_cases) as Total_cases, SUM(new_deaths) as Total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..Covid_Deaths6  
-- WHERE LOCATION LIKE %STATES%
where continent is not NULL
group by date
order by 1,2

--TOTAL CASES NOT GROUP BY DATES

SELECT SUM(new_cases) as Total_cases, SUM(new_deaths) as Total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..Covid_Deaths6  
-- WHERE LOCATION LIKE %STATES%
where continent is not NULL
--group by date
order by 1,2


-- LOOKING AT TOTAL POPULATION VS VACCINATION

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) as  RollingPeopleVaccinated
--(RollingPeopleVaccinated/dea.population)*100 
FROM Covid_Deaths6 as dea
JOIN Covid_Vaccinations6 as vac
ON dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
order by 2,3




-- USE CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS 
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        COALESCE(vac.new_vaccinations, 0) AS new_vaccinations, 
        SUM(CONVERT(INT, COALESCE(vac.new_vaccinations, 0))) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM Covid_Deaths6 AS dea
    JOIN Covid_Vaccinations6 AS vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)

SELECT *, 
       (CAST(RollingPeopleVaccinated AS FLOAT) / population) * 100 AS VaccinationPercentage
FROM PopvsVac;




-- TEMP TABLE
Drop table if EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    location NVARCHAR(255),
    Date datetime, 
    population NUMERIC,
    new_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
 SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        COALESCE(vac.new_vaccinations, 0) AS new_vaccinations, 
        SUM(CONVERT(INT, COALESCE(vac.new_vaccinations, 0))) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM Covid_Deaths6 AS dea
    JOIN Covid_Vaccinations6 AS vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL

    SELECT *, 
       (CAST(RollingPeopleVaccinated AS FLOAT) / population) * 100 AS VaccinationPercentage
FROM #PercentPopulationVaccinated;



-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION

-- Create a view (no `#` for temporary views)
-- CREATING VIEW 
CREATE VIEW PercentagePopulationVaccinated AS
SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        COALESCE(vac.new_vaccinations, 0) AS new_vaccinations, 
        SUM(CONVERT(INT, COALESCE(vac.new_vaccinations, 0))) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM Covid_Deaths6 AS dea
    JOIN Covid_Vaccinations6 AS vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL; 

SELECT * FROM PercentagePopulationVaccinated
WHERE location = 'Canada'

