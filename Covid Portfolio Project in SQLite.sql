/*

Data Exploration of Covid 19 based on dataset from https://ourworldindata.org/covid-deaths

Skills used: Joins, Aggregate Functions, CTE's, Temporary Tables, Windows Functions, Creating Views, Converting Data Types
 
 */

Select *
From Covid_deaths_csv cdc 
Where continent is not null 
order by 3,4

-- Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From Covid_deaths_csv cdc 
WHERE continent is not null
order by 2,1 asc


-- Experimental example: (Looking at Total Cases vs Total Deaths) - not the best approach

Select Location, sum(total_cases), sum(total_deaths), (cast(total_deaths as real) / total_cases) *100  as DeathPercentage
From Covid_deaths_csv cdc 
where continent is not null and location LIKE 'Poland'
group by location, DeathPercentage
order by 1,2 asc


-- Total Cases vs Total Deaths
-- Show likelihood of dying if you contract covid in your country (Poland)

Select Location, date, total_cases, total_deaths, (cast(total_deaths as real) / (total_cases))*100 as DeathPercentage
From Covid_deaths_csv cdc
WHERE location LIKE 'Poland' and continent is not null
order by 1,2 DESC 



-- Total Cases vs number of Population
-- Show what percentage of population got Covid

-- Countries / USA

SELECT location, date,  population, total_cases, ROUND((cast(total_cases as real)/ population) * 100, 3) as PopulationPercentage
FROM Covid_deaths_csv cdc 
WHERE continent is not null 
--and location LIKE '%states%' 
order by 1,2

-- in Poland

SELECT continent, location, date,  population, total_cases, ROUND((cast(total_cases as real)/ population) * 100, 3) as PopulationPercentage
FROM Covid_deaths_csv cdc 
WHERE location LIKE 'Poland' and continent is not null
order by 1,2


-- Countries with Highest Infection Rate Compared to Population


SELECT location, population, MAX(total_cases) AS HighestInfectionCount, ROUND(MAX(cast(total_cases as real)/ population)*100, 3) as PopulationPercentage 
FROM Covid_deaths_csv cdc
where continent is not null
GROUP BY location, population 
ORDER BY PopulationPercentage desc 


-- Countries with Highest Death Count per Population (WITH REQUIRED FILLED CONTINENT FIELD -> NOT NULL VALUE)

SELECT location, MAX(total_deaths) as TotalDeathCount, population 
FROM Covid_deaths_csv cdc 
GROUP BY population, location
HAVING continent IS NOT NULL 
ORDER BY TotalDeathCount  DESC


-- same in other way: (WITH REQUIRED FILLED CONTINENT FIELD -> NOT NULL VALUE)

SELECT location, MAX(total_deaths) as TotalDeathCount, population 
FROM Covid_deaths_csv cdc 
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount DESC



-- Breaking things down by continent
-- Continents with the Highest Death Count per Population

SELECT continent, MAX(total_deaths) as TotalDeathCount, population 
FROM Covid_deaths_csv cdc 
WHERE continent is not null
GROUP BY continent 
ORDER BY TotalDeathCount DESC


-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS TOTAL_CASES, SUM(new_deaths) AS TOTAL_DEATHS, ROUND(SUM(cast(new_deaths as real)) / SUM(new_cases) * 100, 3) AS DeathPercentage
FROM Covid_deaths_csv cdc  
WHERE continent is NOT NULL
GROUP BY date
order by 1,2

-- Total Cases (GLOBAL NUMBERS)
SELECT SUM(new_cases) AS TOTAL_CASES, SUM(new_deaths) AS TOTAL_DEATHS, ROUND(SUM(cast(new_deaths as real)) / SUM(new_cases) * 100, 3) AS DeathPercentage
FROM Covid_deaths_csv cdc  
WHERE continent is NOT NULL
order by 1,2


SELECT * FROM Covid_deaths_csv cdc;

select * from Covid_vaccination_csv cvc


-- WINDOWS FUNCTION:
-- Total population vs Vaccination
-- IT will count sum through location (and start over through next one)
select cdc.continent, cdc.location, cdc.date, cdc.population, cvc.new_vaccinations,
 SUM(cvc.new_vaccinations) OVER (partition by  cdc.location ORDER BY cdc.location, cdc.date) as RollingPeopleVaccinated
from Covid_deaths_csv cdc
LEFT JOIN Covid_vaccination_csv cvc
ON cdc.location = cvc.location and cdc.date = cvc.date
WHERE cdc.continent IS NOT NULL AND cdc.location LIKE 'Poland'
ORDER BY 1,2,3;

-- If You want to make any calculation on created RollingPeopleVaccinated - Use CTE or TEMP TABLE!
-- USE of CTE:

with PopvsVac (Continents, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as (
select cdc.continent, cdc.location, cdc.date, cdc.population, cvc.new_vaccinations,
 SUM(cast(cvc.new_vaccinations as Real)) OVER (partition by  cdc.location ORDER BY cdc.location, cdc.date) as RollingPeopleVaccinated
from Covid_deaths_csv cdc
LEFT JOIN Covid_vaccination_csv cvc
ON cdc.location = cvc.location and cdc.date = cvc.date
WHERE cdc.continent LIKE 'Europe'
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac


-- TEMP TABLE:

DROP TABLE IF EXISTS temp.PercentPopulationVaccinated;


CREATE TEMP TABLE PercentPopulationVaccinated
(
Continent VARCHAR(255),
Location VARCHAR(255),
Date date,
Population INTEGER,
new_vaccinations INTEGER,
RollingPeopleVaccinated INTEGER
);

Insert into PercentPopulationVaccinated
select cdc.continent, cdc.location, cdc.date, cdc.population, cvc.new_vaccinations,
 SUM(cast(cvc.new_vaccinations as Real)) OVER (partition by  cdc.location ORDER BY cdc.location, cdc.date) as RollingPeopleVaccinated
from Covid_deaths_csv cdc
LEFT JOIN Covid_vaccination_csv cvc
ON cdc.location = cvc.location and cdc.date = cvc.date
WHERE cdc.continent LIKE 'Europe';

SELECT *, (cast(RollingPeopleVaccinated as Real)/population)*100
FROM PercentPopulationVaccinated;


-- VIEWS:
-- CREATING View to store data for later visualization

DROP VIEW IF EXISTS PercentPopulationVaccinated 


CREATE View PercentPopulationVaccinated as 
select cdc.continent, cdc.location, cdc.date, cdc.population, cvc.new_vaccinations,
 SUM(cast(cvc.new_vaccinations as Real)) OVER (partition by  cdc.location ORDER BY cdc.location, cdc.date) as RollingPeopleVaccinated
from Covid_deaths_csv cdc
LEFT JOIN Covid_vaccination_csv cvc
ON cdc.location = cvc.location and cdc.date = cvc.date
WHERE cdc.continent is not null;


SELECT * FROM PercentPopulationVaccinated ppv ;


PRAGMA table_info(PercentPopulationVaccinated);
PRAGMA schema_version;
PRAGMA user_version;


/*
	For Tableau visualization:
 */

--1.

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2


--2.

Select continent, SUM(cast(new_deaths as INT)) as TotalDeathCount
From Covid_deaths_csv cdc 
--Where location like '%states%'
Where continent is not NULL
--and location not in ('World', 'European Union', 'International')
Group by continent  
order by TotalDeathCount desc

SELECT * FROM Covid_deaths_csv cdc 

--SELECT location, SUM(cast(new_deaths as REAL)) as TotalDeathCount 
--FROM Covid_deaths_csv cdc 
--WHERE continent is not null and location not in ('World', 'European Union', 'International')
--GROUP BY location
--ORDER BY TotalDeathCount desc;


-- 3.

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, ROUND(MAX(cast(total_cases as real)/ population)*100, 3) as PopulationPercentage 
FROM Covid_deaths_csv cdc
where continent is not null
GROUP BY location, population 
ORDER BY PopulationPercentage desc 


-- 4.

SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount, ROUND(MAX(cast(total_cases as real)/ population)*100, 3) as PopulationPercentage 
FROM Covid_deaths_csv cdc
where continent is not null
GROUP BY location, population , date
ORDER BY PopulationPercentage desc 
