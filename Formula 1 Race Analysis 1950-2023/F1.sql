---------------------------------- FORMULA ONE RACE CHAMPIONSHIP ANALYSIS (1950 - 2023) --------------------------------------

--1. Identify the country which has produced the most F1 drivers.

with cte as (
	select nationality, count(driverid) as no_of_drivers, dense_rank() over(order by count(driverid) desc) as rank
	from drivers d
	group by nationality
	)
select nationality, no_of_drivers from cte where rank = 1;


--2. Which country has produced the most no of F1 circuits.

with cte as (
	select country, count(circuitid) as no_of_circuits, dense_rank() over(order by count(circuitid) desc) as rank
	from circuits
	group by country
	)
select country, no_of_circuits from cte where rank = 1;


--3. Which countries have produced exactly 5 constructors?

select nationality, count(constructorid) as no_of_constructors
from constructors
group by nationality
	having count(constructorid) = 5;


--4. List down the no of races that have taken place each year.

select year, count(raceid) as no_of_races
from races
group by year
order by year desc;


--5. Who is the youngest and oldest F1 driver?

-- Solution 1:
with cte as (
select concat(forename, ' ', surname) as driver, dob, max(dob) over(), min(dob) over()
from drivers
)
select driver, dob, case when dob = max then 'Youngest' else 'Oldest' end as oldest_or_youngest
from cte
where dob = max or dob = min;

-- Solution 2:
select 
	max(case when rn = 1 then forename||' '||surname end) as oldest_driver, 
	max(case when rn = max then forename||' '||surname end) as youngest_driver
from (
	select *, row_number() over(order by dob) as rn, count(*) over() as max
	from drivers
	) x
where rn = 1 or rn = max;


/*6. List down the no of races that have taken place each year and mention which was the first and the last race of 
each season.*/

select 
	distinct(year), 
	count(raceid) over(partition by year) as no_of_races, 
	first_value(name) over(partition by year order by raceid) as first_race, 
	last_value(name) over(partition by year order by raceid rows between unbounded preceding 
	and unbounded following) as last_race
from races
order by year;


--7. Which circuit has hosted the most no of races. Display the circuit name, no of races, city and country.

with cte as (
	select 
		c.name as circuit, 
		location as city, 
		country, 
		count(raceid) as no_of_races,
		dense_rank() over(order by count(raceid) desc) as rank
	from circuits c
	join races r
		on c.circuitid = r.circuitid
	group by circuit, city, country
	)
select circuit, city, country, no_of_races from cte where rank = 1;


/*8. Display the following for 2022 season:
Year, Race_no, circuit name, driver name, driver race position, driver race points, flag to indicate if winner, 
constructor name, constructor position, constructor points, , flag to indicate if constructor is winner, 
race status of each driver, flag to indicate fastest lap for which driver, total no of pit stops by each driver.*/

select 
	distinct(year),
	ra.raceid as race_no,
	cir.name as circuit, 
	concat(d.forename, ' ', d.surname) as driver,
	ds.position as driver_position,
	ds.points as driver_points,
	case when ds.position = 1 then 1 else 0 end as driver_win_flag,
	con.name as constructor,
	cs.position as constructor_position,
	cs.points as constructor_points,
	case when cs.position = 1 then 1 else 0 end as constructor_win_flag,
	s.status,
	lap_time,
	fast_lap_flag,
	no_of_stops
from races ra
join circuits cir on ra.circuitid = cir.circuitid
join driver_standings ds on ra.raceid = ds.raceid
join drivers d on ds.driverid = d.driverid
join constructor_standings cs on ra.raceid = cs.raceid
join constructors con on cs.constructorid = con.constructorid
join results re on ra.raceid = re.raceid
join status s on re.statusid = s.statusid
join pit_stops ps on ra.raceid = ps.raceid
--where year = 2022 and driver = 'Lewis Hamilton'
join (
	select raceid, driverid, count(stop) as no_of_stops
	from pit_stops
	group by raceid, driverid
	) x on d.driverid = x.driverid
--where year = 2022 and concat(d.forename, ' ', d.surname) = 'Lewis Hamilton'
join (
	select race_no1, driverid, case when lap_time = fast_lap then 1 else 0 end as fast_lap_flag 
	from (
		select 
			raceid as race_no1, 
			driverid, 
			time as lap_time,
			min(time) over(partition by raceid, driverid) as fast_lap
		from lap_times
		) fastest_lap
	) y on ra.raceid = y.race_no1
where year = 2022
--and concat(d.forename, ' ', d.surname) = 'Lewis Hamilton';


--9. List down the names of all F1 champions and the no of times they have won it.

with cte as (
	select 
		year, 
		concat(forename, ' ', surname) as driver, 
		sum(points) as total_points,
		dense_rank() over(partition by year order by sum(points) desc) as rank
	from results re
	join drivers d
		on re.driverid = d.driverid
	join races ra
		on re.raceid = ra.raceid
	group by year, driver
	)
select driver, count(driver) as no_of_wins
from cte 
where rank = 1
group by driver 
order by no_of_wins desc;


--10. Who has won the most constructor championships?

with cte1 as (
	select 
		year, 
		c.name as constructor, 
		sum(points), 
		dense_rank() over(partition by year order by sum(points) desc) as rank
	from constructor_results cr
	join constructors c
		on cr.constructorid = c.constructorid
	join races r
		on cr.raceid = r.raceid
	group by year, constructor
	),
	cte2 as (
		select 
			constructor, 
			count(constructor) as no_of_wins, 
			dense_rank() over(order by count(constructor) desc) as rank
		from cte1 
		where rank = 1
		group by constructor
		)
select * from cte2 
where rank = 1;


--11. How many races has India hosted?

select country, count(raceid) as no_of_races
from races r
join circuits c
	on r.circuitid = c.circuitid
where country = 'India'
group by country;


--12. Identify the driver who won the championship or was a runner-up. Also display the team they belonged to.

with cte1 as (
	select 
		distinct(year), 
		concat(forename, ' ', surname) as driver, 
		c.name as team,
		sum(points) over(partition by year, concat(forename, ' ', surname)) as total_points
	from results re
	join drivers d
		on re.driverid = d.driverid
	join races ra
		on re.raceid = ra.raceid
	join constructors c
		on re.constructorid = c.constructorid
	),
	cte2 as (
		select *, dense_rank() over(partition by year order by total_points desc) as rank
		from cte1
		)
select *, case when rank = 1 then 'Winner' else 'Runner' end as position
from cte2 
where rank <= 2;


--13. Display the top 10 drivers with most championship wins. Also display top 10 drivers with most race wins.

-- Top 10 drivers with most championship wins:
with cte1 as (
	select 
		year, 
		concat(forename, ' ', surname) as driver, 
		sum(points) as total_points,
		dense_rank() over(partition by year order by sum(points) desc) as rank
	from results re
	join drivers d
		on re.driverid = d.driverid
	join races ra
		on re.raceid = ra.raceid
	group by year, driver
	),
	cte2 as (
		select driver, count(driver) as no_of_wins, dense_rank() over(order by count(driver) desc) as rank
		from cte1 
		where rank = 1
		group by driver
		)
select * from cte2 
where rank <= 10;

-- Top 10 drivers with most race wins.
with cte as (
	select 
		concat(forename, ' ', surname) as driver, 
		count(concat(forename, ' ', surname)) as race_wins,
		dense_rank() over(order by count(concat(forename, ' ', surname)) desc) as rank
	from drivers d
	join driver_standings ds
		on d.driverid = ds.driverid
	where position = 1
	group by driver
	)
select driver, race_wins
from cte where rank <= 10;


--14. Display the top 3 constructors of all season championship. Also display top 3 constructors with most race wins.

-- Top 3 constructors of all season championship:
with cte1 as (
	select 
		year, 
		c.name as constructor, 
		sum(points), 
		dense_rank() over(partition by year order by sum(points) desc) as rank
	from constructor_results cr
	join constructors c
		on cr.constructorid = c.constructorid
	join races r
		on cr.raceid = r.raceid
	group by year, constructor
	),
	cte2 as (
		select constructor, 
		count(constructor) as no_of_wins, 
		dense_rank() over(order by count(constructor) desc) as rank
		from cte1 
		where rank = 1
		group by constructor
		)
select * from cte2 
where rank <= 3;

-- Top 3 constructors with most race wins:
with cte as (
	select name as constructor, count(name) as race_wins, dense_rank() over(order by count(name) desc) as rank
	from constructors c
	join constructor_standings cs
		on c.constructorid = cs.constructorid
	where position = 1
	group by constructor
	)
select constructor, race_wins 
from cte where rank <= 3;


--15. Identify the drivers who have won races with multiple teams.

select 
	concat(forename, ' ', surname) as driver, 
	count(distinct(name)) as team
from drivers d
join results r
	on d.driverid = r.driverid
join constructors c
	on r.constructorid = c.constructorid
where position = 1
group by driver
	having count(distinct(name)) > 1;


--16. How many drivers have never won any of the season? Also find how many drivers have never won any race?

-- Drivers have never won any of the season:
with cte1 as (
	select 
		year, 
		concat(forename, ' ', surname) as driver, 
		sum(points) as total_points,
		dense_rank() over(partition by year order by sum(points) desc) as rank
	from results re
	join drivers d
		on re.driverid = d.driverid
	join races ra
		on re.raceid = ra.raceid
	group by year, driver
	),
	cte2 as (
		select distinct(driver) as driver
		from cte1
		where rank = 1
		)
select distinct(count(concat(d.forename, ' ', d.surname))) as drivers_never_won
from cte2 c
right join drivers d
	on c.driver = concat(d.forename, ' ', d.surname)
where c.driver is null;

-- Drivers have never won any race:
select driverid, concat(forename, ' ', surname) as driver
from drivers
where driverid not in (
						select distinct(driverid) as driver
						from driver_standings 
						where position = 1
						);

					
/*17. Are there any constructors who never scored a point? if so mention their name and how many races they 
participated in?*/

select c.name as constructor, count(r.raceid) as no_of_races, sum(points) as total_points
from constructor_results cr
join races r
	on cr.raceid = r.raceid
join constructors c
	on cr.constructorid = c.constructorid
group by constructor
	having sum(points) = 0;


--18. Mention the drivers who have won more than 50 races.

select concat(forename, ' ', surname) as driver, count(concat(forename, ' ', surname)) as race_wins
from drivers d
join driver_standings ds
	on d.driverid = ds.driverid
where position = 1
group by driver
	having count(concat(forename, ' ', surname)) > 50;


--19. Identify the podium finishers of each race in 2022 season.

with cte as (
	select 
		year, 
		ra.raceid as race_id,
		name as race,
		concat(forename, ' ', surname) as driver, 
		sum(points) as total_points,
		dense_rank() over(partition by year, ra.raceid order by sum(points) desc) as rank
	from results re
	join drivers d
		on re.driverid = d.driverid
	join races ra
		on re.raceid = ra.raceid
	group by year, race_id, race, driver
		having year = 2022
	)
select * from cte 
where rank <= 3;


/*20. For 2022 season, mention the points structure for each position (i.e. how many points are awarded to 
each race finished position).*/

with cte as (
	select min(ra.raceid) as raceid
	from races ra
	join results re
		on ra.raceid = ra.raceid
	where year = 2022
	)
select position, points 
from results r 
join cte c
	on c.raceid = r.raceid
where points > 0;


--21. How many drivers participated in 2022 season?

select year, count(distinct(d.driverid)) as no_of_drivers
from drivers d
join driver_standings ds
	on d.driverid = ds.driverid
join races ra
	on ds.raceid = ra.raceid
group by year
	having year = 2022;	
	

--22. How many races has the top 5 constructors won in the last 10 years.

with cte1 as (
	select 
		year,
		c.constructorid,
		c.name as constructor,
		sum(points) as total_points, 
		dense_rank() over(partition by year order by sum(points) desc) as rank
	from constructors c
	join constructor_results cr
		on c.constructorid = cr.constructorid
	join races r
		on cr.raceid = r.raceid
	group by year, c.constructorid, constructor
		having year >= (extract(year from current_date)) - 10  -----data available till 2023, data not updated for 2024 & 2025.
	),
	cte2 as (
		select 
			constructorid,
			constructor,
			count(constructor) as championship_wins, 
			dense_rank() over(order by count(constructor) desc) as rank
		from cte1
		where rank = 1
		group by constructorid, constructor
		)
select 
	constructor, 
	championship_wins,--championship_wins split into 7+1=8 for 8 yrs,data not updated for 2024 & 2025(no wins for last 2 yrs).
	count(constructor) as race_wins 
from cte2 ct
join constructor_standings cs
	on ct.constructorid = cs.constructorid
where position = 1
group by constructor, championship_wins;


--23. Display the winners of every sprint so far in F1.

select raceid, concat(forename, ' ', surname) as driver
from sprint_results sr
join drivers d
	on sr.driverid = d.driverid
where position = 1;


--24. Find the driver who did not qualify in most races.

select driver, no_of_times_not_qualified
from (
	select 
		concat(forename, ' ', surname) as driver, 
		count(1) as no_of_times_not_qualified, 
		dense_rank() over(order by count(1) desc) as rank
	from results r
	join status s
		on r.statusid = s.statusid
	join drivers d
		on r.driverid = d.driverid
	where s.status = 'Did not qualify'
	group by driver
	)
where rank = 1;


--25. During the last race of 2022 season, identify the drivers who did not finish the race and the reason for it.

select concat(forename, ' ', surname) as driver, status
from results re
join status s
	on re.statusid = s.statusid
join drivers d
	on re.driverid = d.driverid
join races ra
	on re.raceid = ra.raceid
where ra.raceid = (select max(raceid) from races where year = 2022) and status != 'Finished'


--26. What is the average lap time for each F1 circuit. Sort based on least lap time.

select c.name as circuit, avg(lt.time) as avg_lap_time    ---------- lap time data is not available for few circuits
from circuits c
join races r
	on c.circuitid = r.circuitid
left join lap_times lt
	on r.raceid = lt.raceid
group by c.name
order by avg_lap_time;


--27. Who won the drivers championship when India hosted F1 for the first time?

with cte1 as (
	select 
		year, 
		country, 
		concat(forename, ' ', surname) as driver, 
		sum(points),
		dense_rank() over(partition by year order by sum(points) desc) as rank
	from results re
	join races ra
		on re.raceid = ra.raceid
	join circuits c
		on ra.circuitid = c.circuitid
	join drivers d
		on re.driverid = d.driverid
	group by year, country, driver
	),
	cte2 as (
		select *, dense_rank() over(order by year) as nth_year
		from cte1
		where rank = 1 and country = 'India'
		)
select year, country, driver
from cte2
where nth_year = 1;


--28. Which driver has done the most lap time in F1 history?

with cte as (
	select 
		concat(forename, ' ', surname) as driver, 
		sum(time) as total_lap_time, 
		dense_rank() over(order by sum(time) desc) as rank
	from lap_times lt
	join drivers d
		on lt.driverid = d.driverid
	group by driver
	)
select driver, total_lap_time
from cte where rank = 1;


--29. Name the top 3 drivers who have got the most podium finishes in F1 (Top 3 race finishes).

with cte1 as (
	select 
		year, 
		concat(forename, ' ', surname) as driver, 
		sum(points) as total_points, 
		dense_rank() over(partition by year order by sum(points) desc) as rank
	from results re
	join drivers d
		on re.driverid = d.driverid
	join races ra
		on re.raceid = ra.raceid
	group by year, driver
	),
	cte2 as (
		select driver, count(driver) as podium_finishes, dense_rank() over(order by count(driver) desc) as rank
		from cte1
		where rank <= 3
		group by driver
		)
select driver, podium_finishes
from cte2
where rank <= 3;

	
--30. Which driver has the most pole position (no 1 in qualifying).

select driver, pole_positions
from (
	select 
		concat(forename, ' ', surname) as driver, 
		count(concat(forename, ' ', surname)) as pole_positions,
		dense_rank() over(order by count(concat(forename, ' ', surname)) desc) as rank
	from qualifying q
	join drivers d
		on q.driverid = d.driverid
	where position = 1
	group by driver
	) x
where rank = 1;

