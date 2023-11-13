
-- This project explores real world covid-19 data through queries.

-- This query allows us to view the covid deaths data according to the location alphabetically starting from the earliest date
select location, date, population, total_cases, new_cases, total_deaths
from portfolioproject..coviddeaths
order by location, date;

-- Some information we are able to see immediately: The first death occurred about one month after its first case in Afghanistan.
-- Observe if this is consistent with other countries. 


-- Looking at total cases vs. total deaths
-- This query takes the total_deaths and divides it by the total_cases and returns the likelihood of dying from covid. 
-- For example, there was 1 death and 34 total cases in Afghanistan on 03/22/2020, which is a 2.94% death rate. 
-- However, the next day there was still only 1 total death and 41 total cases, which produce a new death rate of 2.43%. 
-- This is due to the low number of cases and deaths as the pandemic had only begun. 
-- The last entry for Afghanistan states there were 2625 total deaths and 59745 total cases, which is a 4.39% death rate.
select location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 as deaths_per_case
from portfolioproject..coviddeaths
order by location, date;


-- Let's observe the data in the United States
-- The last entry on 12/29/2020 reveals 344822 deaths from 19630012 cases, with a percent of 1.76%.
select location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 as death_by_covid
from portfolioproject..coviddeaths
where location = 'United States'
order by location, date;

-- Looking at total cases vs. population 
-- This query shows what percentage of the US population contracted covid
select location, date, total_cases, population, (total_cases / population) * 100 as infection_rate
from portfolioproject..coviddeaths
where location = 'United States'
order by location, date;

-- Looking at countries with the highest infection rate compared to population
-- We can see that Andorra has the highest infection rate of 17.1%, whereas the US's highest infection rate
-- was 9.77%. However, the US has a higher number of cases, but in relation to its population, the US's highest infection rate
-- is lower. 
select location, population, max(total_cases) as max_cases, max(total_cases / population) * 100 as highest_infection_rate
from portfolioproject..coviddeaths
group by location, population
order by highest_infection_rate desc;


-- Looking at countries with the highest deaths per population
-- order by total_deaths (before cast) does not order it numerically due to its data type as a varchar
-- and so we need to cast / change it to an integer

-- We also have an issue where some countries are listed as continents or 'World', and so some continents
-- are null
select location, population, max(cast(total_deaths as int)) as max_deaths, max(cast(total_deaths as int) / population) * 100 as highest_death_rate
from portfolioproject..coviddeaths
where continent is not null
group by location, population
order by highest_death_rate desc;


-- Breaking things down by continent
-- One issue with this data set is that filtering the data by a not null continent does not
-- accurately sum all of the values for each continent
-- However, filtering by null continent and grouping by continent fixes thsi

-- This query only includes the US deaths in North America
select continent, max(cast(total_deaths as int)) as max_deaths
from portfolioproject..coviddeaths
where continent is not null
group by continent
order by max_deaths desc;

-- This query includes other countries in NA
select location, max(cast(total_deaths as int)) as max_deaths
from portfolioproject..coviddeaths
where continent is null
group by location
order by max_deaths desc;


-- Global Numbers (no continent, location)

select date, sum(new_cases) as cases, sum(cast(new_deaths as int)) as deaths,
	(sum(cast(new_deaths as int)) / sum(new_cases)) * 100 as death_rate
from portfolioproject..coviddeaths
where continent is not null
group by date
order by 1, 2;

-- Across the world, the percentage of deaths from covid is 2.11% with over 3 million deaths from over 
-- 150 million cases.
select sum(new_cases) as cases, sum(cast(new_deaths as int)) as deaths,
	(sum(cast(new_deaths as int)) / sum(new_cases)) * 100 as death_rate
from portfolioproject..coviddeaths
where continent is not null
order by 1, 2;


-- Looking at deaths and vaccinations
select d.continent, d.location, d.date, d.population, v.new_vaccinations
from portfolioproject..coviddeaths d 
	join portfolioproject..covidvaccinations v
		on d.location = v.location and d.date = v.date
where d.continent is not null
order by 1, 2, 3;

-- Include a rolling count of vaccinations using partition by location
-- Want the count to start over for each new location
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
	sum(cast(v.new_vaccinations as int)) over (partition by d.location order by d.location, d.date) as rolling_count
from portfolioproject..coviddeaths d 
	join portfolioproject..covidvaccinations v
		on d.location = v.location and d.date = v.date
where d.continent is not null
order by 1, 2, 3;

-- using a CTE to find out what percent of the population is vaccinated for each location per day
with population_vaccinated (continent, location, date, population, new_vaccinations, rolling_count)
as (
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
	sum(cast(v.new_vaccinations as int)) over (partition by d.location order by d.location, d.date) as rolling_count
from portfolioproject..coviddeaths d 
	join portfolioproject..covidvaccinations v
		on d.location = v.location and d.date = v.date
where d.continent is not null
)
select *, (rolling_count / population) * 100 as vaccination_rate
from population_vaccinated
order by 1, 2, 3;

-- using a temp table instead
drop table if exists #population_vaccinated
create table #population_vaccinated (
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_count numeric)

insert into #population_vaccinated
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
	sum(cast(v.new_vaccinations as int)) over (partition by d.location order by d.location, d.date) as rolling_count
from portfolioproject..coviddeaths d 
	join portfolioproject..covidvaccinations v
		on d.location = v.location and d.date = v.date
where d.continent is not null;

select *, (rolling_count / population) * 100 as vaccination_rate
from #population_vaccinated
order by 1, 2, 3;

-- creating a view to store data
create view percent_population_vaccinated as
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
	sum(cast(v.new_vaccinations as int)) over (partition by d.location order by d.location, d.date) as rolling_count
from portfolioproject..coviddeaths d 
	join portfolioproject..covidvaccinations v
		on d.location = v.location and d.date = v.date
where d.continent is not null;
