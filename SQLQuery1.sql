select *
from PortfolioProject..CovidDeaths
order by 3, 4;

-- We will select the data that will be used

-- Order by 1, 2 means the first and second column (location and date)
Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Order by 1, 2;

-- Total Cases vs Total Deaths (Percentage) in the United States
-- This shows the likelihood of experiencing death if a person contracts covid in your country (United States in particular)
-- We can see that the number of cases increased significantly (reaching over 32 million by April 30)
-- in which the percentage of deaths reached its peak of ~6.26% in May, and gradually decreasing over time
-- percentage of deaths caused by covid
Select location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 as deaths_percentage
From PortfolioProject..CovidDeaths
Where location = 'United States'
Order by 1, 2;


-- Total Cases vs Population
-- This shows what percent of the population contracted covid by date
Select location, date, total_cases, population, (total_cases / population) * 100 as cases_percentage
From PortfolioProject..CovidDeaths
Where location = 'United States'
Order by 1, 2;


-- Countries with highest infection rates compared to population
Select location, population, max(total_cases) as max_num_cases, max((total_cases / population)) * 100 as max_infected_percentage
From PortfolioProject..CovidDeaths
Group by location, population
Order by max_infected_percentage desc;


-- Countries with the highest number of deaths per population
Select location, max(cast(total_deaths as int)) as max_deaths
from PortfolioProject..CovidDeaths
where continent is not null
Group by location
order by max_deaths desc;

-- Continents with the highest number of deaths per population
Select location, max(cast(total_deaths as int)) as max_deaths
from PortfolioProject..CovidDeaths
where continent is null
Group by location
order by max_deaths desc;

-- GLOBAL NUMBERS
-- does NOT include location or continents
-- change data type of new_deaths nvarchar to an int
Select date, sum(new_cases) as cases, sum(cast(new_deaths as int)) as deaths, (sum(cast(new_deaths as int)) / sum(new_cases)) * 100 as percentage  --, (total_deaths / total_cases) * 100 as deaths_percentage
From PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1, 2;


-- Total Population vs Vaccinations
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations
from PortfolioProject..CovidDeaths deaths JOIN PortfolioProject..CovidVaccinations vaccinations
	ON deaths.location = vaccinations.location AND deaths.date = vaccinations.date
where deaths.continent is not null
order by 1, 2, 3;


-- Show a rolling count of new vaccinations by location
-- Convert (or cast) new vaccinations as an int
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
	sum(convert(int, vaccinations.new_vaccinations)) over (partition by deaths.location order by deaths.location, deaths.date) as rolling_count
from PortfolioProject..CovidDeaths deaths JOIN PortfolioProject..CovidVaccinations vaccinations
	ON deaths.location = vaccinations.location AND deaths.date = vaccinations.date
where deaths.continent is not null
order by 2, 3;

-- CTE
With PopvsVac (continent, location, date, population, new_vaccinations, rolling_count)
as
(
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
	sum(convert(int, vaccinations.new_vaccinations)) over (partition by deaths.location order by deaths.location, deaths.date) as rolling_count
from PortfolioProject..CovidDeaths deaths JOIN PortfolioProject..CovidVaccinations vaccinations
	ON deaths.location = vaccinations.location AND deaths.date = vaccinations.date
where deaths.continent is not null
)
Select *, (rolling_count / population) * 100
From PopvsVac;

-- using a temp table
drop table if exists #PercentPopVaccinated --good to include in case of making changes
create table #PercentPopVaccinated (
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
rolling_count numeric)

Insert into #PercentPopVaccinated
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
	sum(convert(int, vaccinations.new_vaccinations)) over (partition by deaths.location order by deaths.location, deaths.date) as rolling_count
from PortfolioProject..CovidDeaths deaths JOIN PortfolioProject..CovidVaccinations vaccinations
	ON deaths.location = vaccinations.location AND deaths.date = vaccinations.date
where deaths.continent is not null

Select *, (rolling_count / population) * 100
From #PercentPopVaccinated;

-- Create view to store data
create view PercentPopVaccinated as
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
	sum(convert(int, vaccinations.new_vaccinations)) over (partition by deaths.location order by deaths.location, deaths.date) as rolling_count
from PortfolioProject..CovidDeaths deaths JOIN PortfolioProject..CovidVaccinations vaccinations
	ON deaths.location = vaccinations.location AND deaths.date = vaccinations.date
where deaths.continent is not null;


Select *, (rolling_count / population) * 100
From PercentPopVaccinated;