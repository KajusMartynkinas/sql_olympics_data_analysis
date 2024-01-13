-- 1. How many olympics games have been held
select count(distinct games) as total_olympics_games
from olympic_history



-- 2. All Olympics games held so far
select distinct year, season, city
from olympic_history
order by year



-- 3. Total number of nations who participated in each olympics game
select games, count(distinct noc) as total_countries
from olympic_history
group by games



-- 4. Number of games in each season
select season, count(distinct games)
from olympic_history
group by season



-- 5. Which year saw the highest and lowest number of countries participating in olympics
with all_countries as
(select games, nr.region
from olympic_history oh
join olympics_history_noc_regions nr ON nr.noc=oh.noc
group by games, nr.region),
tot_countries as
(select games, count(1) as total_countries
from all_countries
group by games)
select distinct
concat(first_value(games) over(order by total_countries)
, ' - '
, first_value(total_countries) over(order by total_countries)) as Lowest_Countries,
concat(first_value(games) over(order by total_countries desc)
, ' - '
, first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
from tot_countries
order by 1;



-- 6. Total number of sports played in each olympic game
select games, count(distinct sport) as number_of_sports
from olympic_history
group by games



-- 7. Top 5 athletes who have won the most gold medals
with t1 as
    (select name, count(medal) as gold_medals
    from olympic_history
    where medal like 'Gold'
    group by name
    order by gold_medals desc),
t2 as
    (select *, dense_rank() over(order by gold_medals desc) as rnk
    from t1)
select *
from t2
where rnk <= 5;



-- 8. List down total gold, silver and bronze medals won by each country
select nr.region as country, medal, count(1) as total_medals
from olympic_history oh
join olympics_history_noc_regions nr on nr.noc = oh.noc
where medal <> 'NA'
group by nr.region, medal
order by  nr.region, medal;

select country
, coalesce(gold, 0) as gold
, coalesce(silver, 0) as silver
, coalesce(bronze, 0) as bronze
from crosstab('select nr.region as country, medal, count(1) as total_medals
from olympic_history oh
join olympics_history_noc_regions nr on nr.noc = oh.noc
where medal <> ''NA''
group by nr.region, medal
order by  nr.region, medal',
'values (''Gold''), (''Silver''), (''Bronze'')')
as result(country varchar, gold bigint, silver bigint, bronze bigint)
order by gold desc, silver desc, bronze desc



-- 9. Which country won the most gold, most silver and most bronze medals in each olympic game
with temp as
    (select substring(games_country, 1, position('-' in games_country) - 1) as games
    , substring(games_country, position('-' in games_country) + 1) as country
    , coalesce(gold, 0) as gold
    , coalesce(silver, 0) as silver
    , coalesce(bronze, 0) as bronze
    from crosstab('select concat(games, ''-'', nr.region) as games_country, medal, count(1) as total_medals
    from olympic_history oh
    join olympics_history_noc_regions nr on nr.noc = oh.noc
    where medal <> ''NA''
    group by games, nr.region, medal
    order by  games, nr.region, medal',
    'values (''Gold''), (''Silver''), (''Bronze'')')
    as result(games_country varchar, gold bigint, silver bigint, bronze bigint)
    order by games_country)

select distinct games,
concat(first_value(country) over (partition by games order by gold desc), ' - ',
    first_value(gold) over (partition by games order by gold desc)) as gold,
concat(first_value(country) over (partition by games order by silver desc), ' - ',
    first_value(silver) over (partition by games order by silver desc)) as silver,
concat(first_value(country) over (partition by games order by bronze desc), ' - ',
    first_value(bronze) over (partition by games order by bronze desc)) as bronze
from temp
order by games;







