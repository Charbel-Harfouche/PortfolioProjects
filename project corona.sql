--Project for coronavirus in Canada
--Data gathered from https://ourworldindata.org/covid-deaths
--data imported from a .cvs file to a single large table



--project scope:

-- Total deaths and mortality rate by continents
-- Global infection rate by continent
-- Covid mortality rate in Canada
-- How does Canada's Covid mortality rate rank compared to other countries
-- How many Canadians got infected as a percentage of total population
-- What is canada's ranking in infection rate
-- What percentage of the world got vaccinated
-- what percentage by country got vaccinated
-- total Population vs total vaccinations using values in daily New_vaccinations

select * from coviddataCVS
where location like 'Canada'


-- Total deaths by Continents
-- First we find the appropriate locations to display by going through the Location column and finding unnecessary rows
select distinct location from CovidDataCVS
where continent is null and location not in ('lower middle income', 'low income', 'European Union', 'Upper middle income', 'High income')


-- Now we display the Total Deaths in each continent including the whole world
select codata.location, population, Total_deaths, (total_deaths/population)*100 as MortalityRate  from CovidDataCVS as codata
join (select location, Max(date) as mdate from CovidDataCVS 
where continent is null and Total_deaths is not null and location not in 
('lower middle income', 'low income', 'European Union', 'Upper middle income', 'High income')group by location) as b
on b.location=codata.location and b.mdate=codata.date
order by population desc

-- Now using CTE
With Latest_TotalDeaths_By_Continents (location, Mdate) as
(
select location, Max(date) from CovidDataCVS 
where continent is null and Total_deaths is not null and location not in ('lower middle income', 'low income', 'European Union', 'Upper middle income', 'High income')
group by location
)
select codata.location, population, Total_deaths, (total_deaths/population)*100 as MortalityRate  from CovidDataCVS as codata
join Latest_TotalDeaths_By_Continents on Latest_TotalDeaths_By_Continents.location=codata.location and Latest_TotalDeaths_By_Continents.mdate=codata.date
order by population desc

-- Global Infection rate by continent
Select codata.location, population, total_cases, (total_cases/population)*100 as InfectionRate from CovidDataCVS as codata
join (select location, Max(date) as Mdate from CovidDataCVS where Total_cases is not null and continent is null and location not in
('lower middle income', 'low income', 'European Union', 'Upper middle income', 'High income')
group by location) as b on codata.location = b.location and codata.date = b.Mdate
order by population desc
-- Africa's very low infection rate could be attributed to a lack of reporting and data in the region. This might be a recurring theme with poor countries.


-- Canada's mortality rate for covid-19
-- mortality rate of virus = total deaths / total cases
Select location, population, date, total_deaths, total_cases, (total_deaths/total_cases)*100 as CovidMortality_rate from coviddataCVS
where location like 'canada' and total_deaths is not null and total_cases is not null
order by date desc
-- Canada's mortality rate for Covid is 1.13% as of 2024-02-18


-- How does Canada's mortality rate rank compared to other countries
-- in order to have an aggregate function such as max(date) with 2 other columns, we will have to join 2 tables, one that has the 3 initial columns
-- without any aggregate function, and then another table that has the aggregate function and the grouped by column. We then join them based on
-- the grouped by column and the column with the aggregate function. 
select codata.location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as MortalityRate from CovidDataCVS as codata
join (select location, max(date) Mdate from coviddatacvs where total_deaths is not null and total_cases is not null and continent is not null group by location) as b
on codata.location = b.location and codata.date=b.mdate
order by MortalityRate desc
--Canada ranks 95 out of 226 territories in terms of Highest mortality rate
--Canada's mortality rate is below the median


-- How many Canadians got infected with covid?
-- total cases vs population for Canada
select location, date, population, total_cases ,(total_cases/population)*100 as InfectionRate from CovidDataCVS
where location like 'canada' and total_cases is not null
order by date desc
-- As of 2024-02-18, the infection rate in Canada is 12.42% (12.42% of Canada's population got infected by covid)


-- What is Canada's ranking in infection rate?
-- location, latest date with infection rate, infection rate
-- join table1(location , max(date) where columns not null group by location) to table2(location, date, infection rate)
select codata.location, date, population,total_cases, (codata.total_cases/codata.population)*100 as InfectionRate from CovidDataCVS as codata
join (select location, max(date) as Mdate from Coviddatacvs where continent is not null and total_cases is not null group by location ) as b 
on codata.location = b.location and codata.date = b.mdate
order by InfectionRate desc
--Canada ranks 124 out of 232 territories in worst Infection rate.
--Canada's infection rate is below the median.

--the function below is a different way of doing it but is unreliable because having the latest data [Max(date)] is always better
--than getting the highest number of Total_cases [Max(total_cases)]
--Sometimes, corrections are made like in the case of Liberia where Total_cases got reduced from 8090 to 7930 on 2023-08-13
--Always get the latest data through the Date Column
select location, max(total_cases)as MaxCases, max(total_cases/population)*100 as InfectionRate from CovidDataCVS
where total_cases is not null and continent is not null
group by location
order by InfectionRate desc


-- What percentage of the world got vaccinated
-- the query below gives us a simple idea of the columns we're working with
Select location, population, date, total_vaccinations, people_fully_vaccinated, new_vaccinations from CovidDataCVS
where location = 'gibraltar'
order by date desc

select codata.location, population, total_vaccinations, people_fully_vaccinated, (people_fully_vaccinated/population)*100 as VaccinationRate from CovidDataCVS as codata
join (select location, Max(date) as Mdate from CovidDataCVS where continent is null and people_fully_vaccinated is not null and location not in
('lower middle income', 'low income', 'European Union', 'Upper middle income', 'High income') group by location) as b
on b.location = codata.location and b.Mdate=codata.date
order by population desc

-- Now using Temp table
Drop table if exists #latest_PeopleFullyVaccinated_By_Continent
Create table #latest_PeopleFullyVaccinated_By_Continent (
location nvarchar(50),
Mdate date)
Insert into #latest_PeopleFullyVaccinated_By_Continent Select location, Max(date) as Mdate from CovidDataCVS where continent is null and people_fully_vaccinated is not null and location not in
('lower middle income', 'low income', 'European Union', 'Upper middle income', 'High income')
group by location
Select * from #latest_PeopleFullyVaccinated_By_Continent

select codata.location, population, total_vaccinations, people_fully_vaccinated, (people_fully_vaccinated/population)*100 as VaccinationRate from CovidDataCVS as codata
join #latest_PeopleFullyVaccinated_By_Continent
on #latest_PeopleFullyVaccinated_By_Continent.location = codata.location and #latest_PeopleFullyVaccinated_By_Continent.Mdate=codata.date
order by population desc



-- What is the vaccination rate by country
Select codata.location, population, people_fully_vaccinated, (people_fully_vaccinated/population)*100 as VaccinationRate from CovidDataCVS as codata
join (select location, Max(date) as Mdate from CovidDataCVS where continent is not null and people_fully_vaccinated is not null and location not in
('lower middle income', 'low income', 'European Union', 'Upper middle income', 'High income') group by location) as b
on b.location=codata.location and b.Mdate=codata.date
order by VaccinationRate desc
--contries with VaccinationRate above 100% are probably counting foreigners with their own population.


-- Total population vs total vaccinations Uuing the daily values in New_vaccinations
Select codata.location, date, population, new_vaccinations, sum(new_vaccinations) over (partition by codata.location) from CovidDataCVS as codata
where continent is not null and new_vaccinations is not null and people_fully_vaccinated is not null and location not in ('lower middle income', 'low income', 'European Union', 'Upper middle income', 'High income')


-- Same as above but doing a rolling count
Select codata.location, date, population, new_vaccinations, sum(new_vaccinations) over (partition by codata.location order by date) from CovidDataCVS as codata
where continent is not null and new_vaccinations is not null and people_fully_vaccinated is not null and location not in ('lower middle income', 'low income', 'European Union', 'Upper middle income', 'High income')


