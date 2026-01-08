SELECT *
From portfolioProject0.dbo.CovidDeaths$
Order by 3,4;

SELECT *
From portfolioProject0.dbo.CovidVaccinations$
Order by 3,4;

SELECT location, date, total_cases, new_cases, total_deaths, population
From portfolioProject0.dbo.CovidDeaths$
Order by 1,2;

-- Looking at total cases vs total deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_percentage -- shows likelilhood of dying if you contact covid in your country
From portfolioProject0.dbo.CovidDeaths$
Where location LIKE '%viet%'
Order by 1,2;

-- Looking at total_cases vs population

SELECT location, date, population, total_cases, (total_cases/population)*100 AS exposing_percentage -- shows what percentage of population exposing to covid.
From portfolioProject0.dbo.CovidDeaths$
-- Where location LIKE '%viet%'
Order by 1,2;

-- Looking at countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS Highest_infection_count, MAX((total_cases/population))*100 AS percent_population_infected
From portfolioProject0.dbo.CovidDeaths$
-- Where location LIKE '%viet%'
Group By location, population
Order by percent_population_infected desc;

-- Showing countries with highest death counts per population

SELECT location, MAX(cast(total_deaths as int)) as total_death_count
From portfolioProject0.dbo.CovidDeaths$
Where continent IS NOT null -- because where continent is null, location is the continent's value (Asia, South Asia, Europe, East Europe, etc.). This is to show only country names in location column. 
Group By location 
Order by total_death_count desc;

-- Showing continents with the highest death counts

SELECT continent, MAX(cast(total_deaths as int)) as total_death_count
From portfolioProject0.dbo.CovidDeaths$
Where continent IS NOT null -- there is null value in continent column, so let's get rid of that.
Group By continent 
Order by total_death_count desc;
-- if we do this, the number showing in the talbe is not reflected correctly because there are values in location column that is also continent's value, given that the continent's value on the same row is null. 

-- Let's fix that by doing this

SELECT location, MAX(cast(total_deaths as int)) as total_death_count
From portfolioProject0.dbo.CovidDeaths$
Where continent IS null -- easy fix, just remove 'not'
Group By location 
Order by total_death_count desc;

-- Looking at global numbers
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS Death_percentage 
From portfolioProject0.dbo.CovidDeaths$
-- Where location LIKE '%viet%'
where continent is not null
--group by date, can select date value should you change your mind later
Order by 1,2;

--Joining two table

SELECT *
From portfolioProject0.dbo.CovidDeaths$ dea
	JOIN portfolioProject0.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date;

-- Looking at total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as int)) OVER (partition by dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated-- can also use CONVERT(int,...)
From portfolioProject0.dbo.CovidDeaths$ dea
	JOIN portfolioProject0.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	ORDER BY 1,2,3
;

-- USE CTE
WITH PopulationVSVaccination (continent, location, date, population, new_vaccinations, Rolling_People_Vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
From portfolioProject0.dbo.CovidDeaths$ dea
	JOIN portfolioProject0.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)

SELECT *, (Rolling_People_Vaccinated/population)*100 AS percentage_people_vaccinated
FROM PopulationVSVaccination
ORDER BY 2,3
;

-- TEMP TABLE
DROP TABLE IF exists PercentPopulationVaccinated -- this is so that if you need to make any change to the temp table but don't want to create multiple temp tables
CREATE TABLE PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
Rolling_people_vaccinated numeric
)

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
From portfolioProject0.dbo.CovidDeaths$ dea
	JOIN portfolioProject0.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
	WHERE dea.continent IS NOT NULL

SELECT *, (Rolling_People_Vaccinated/population)*100 AS percentage_people_vaccinated
	FROM PercentPopulationVaccinated
	ORDER BY 2,3
;

-- Creating view to store data for later purpose
DROP VIEW IF exists PercentagePopulationVaccinated;
GO -- important to separate batches (SSMS/ Azure Data Studio), if there's no GO then the view cannot be created due to conflict with CREATE VIEW must be the only statement in the patch. 

CREATE VIEW PercentagePopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
From portfolioProject0.dbo.CovidDeaths$ dea
	JOIN portfolioProject0.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
	WHERE dea.continent IS NOT NULL
;
GO

SELECT *
FROM PercentagePopulationVaccinated;