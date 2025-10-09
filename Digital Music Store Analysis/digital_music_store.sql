-----------------------------------------CHINOOK DIGITAL MUSIC STORE ANALYSIS ------------------------------------------------

--1) Find the artist who has contributed with the maximum no of albums. Display the artist name and the no of albums.

with cte as (
	select name as artist, count(albumid) as no_of_albums, dense_rank() over(order by count(albumid) desc) as rank
	from artist ar
	join album al
		on ar.artistid = al.artistid
	group by name
	)
select artist, no_of_albums from cte where rank = 1;


--2) Display the name, email id, country of all listeners who love Jazz, Rock and Pop music.

select distinct(concat(firstname, ' ', lastname)) as listener, email, country, g.name as genre
from customer c
join invoice i
	on c.customerid = i.customerid
join invoiceline il
	on i.invoiceid = il.invoiceid
join track t
	on il.trackid = t.trackid
join genre g
	on t.genreid = g.genreid
where g.name in ('Jazz', 'Rock', 'Pop');


--3) Find the employee who has supported the most no of customers. Display the employee name and designation.

with cte as (
	select 
		concat(e.firstname, ' ', e.lastname) as employee, 
		title as designation, 
		count(customerid) as no_of_customers,
		dense_rank() over(order by count(customerid) desc) as rank
	from customer c
	join employee e
		on c.supportrepid = e.employeeid
	group by employee, designation
	)
select employee, designation, no_of_customers from cte where rank = 1;


--4) Which city corresponds to the best customers?

with cte as (
	select city, sum(unitprice * quantity) as total_sales, dense_rank() over(order by sum(unitprice * quantity) desc) as rank
	from customer c
	join invoice i
		on c.customerid = i.customerid
	join invoiceline il
		on i.invoiceid = il.invoiceid
	group by city
	)
select city, total_sales from cte where rank = 1;


--5) The highest number of invoices belongs to which country?

with cte as (
	select country, count(invoiceid) as no_of_invoices, dense_rank() over(order by count(invoiceid) desc) as rank
	from customer c
	join invoice i
		on c.customerid = i.customerid
	group by country
	)
select country, no_of_invoices from cte where rank = 1;


--6) Name the best customer (customer who spent the most money).

with cte as (
	select 
		concat(firstname, ' ', lastname) as customer, 
		sum(unitprice * quantity) as total_sales, 
		dense_rank() over(order by sum(unitprice * quantity) desc) as rank
	from customer c
	join invoice i
		on c.customerid = i.customerid
	join invoiceline il
		on i.invoiceid = il.invoiceid
	group by customer
	)
select customer, total_sales from cte where rank = 1;


--7) Suppose you want to host a rock concert in a city and want to know which location should host it.

with cte as (
	select city, count(g.genreid) as no_of_listeners, dense_rank() over(order by count(g.genreid) desc) as rank
	from customer c
	join invoice i
		on c.customerid = i.customerid
	join invoiceline il
		on i.invoiceid = il.invoiceid
	join track t
		on il.trackid = t.trackid
	join genre g
		on t.genreid = g.genreid
	where g.name = 'Rock'
	group by city
	)
select city, no_of_listeners from cte where rank = 1;


/*8) Identify all the albums who have less than 5 track under them. Display the album name, artist name and the no of tracks 
in the respective album.*/

with cte as (
	select 
		title as album, 
		ar.name as artist, 
		trackid, 
		count(trackid) over(partition by title) as no_of_tracks, 
		row_number() over(partition by title) as rn
	from album al
	join track t
		on al.albumid = t.albumid
	join artist ar
		on al.artistid = ar.artistid
	)
select album, artist, no_of_tracks
from cte
where rn = 1 and no_of_tracks < 5
order by no_of_tracks desc;


--9) Display the track, album, artist and the genre for all tracks which are not purchased.

-- Solution 1:
select t.name as track, al.title as album, ar.name as artist, g.name as genre
from track t
join album al
	on t.albumid = al.albumid
join artist ar
	on al.artistid = ar.artistid
join genre g
	on t.genreid = g.genreid
left join invoiceline il
	on t.trackid = il.trackid
where il.trackid is null;

-- Solution 2:
select t.name as track, al.title as album, ar.name as artist, g.name as genre
from track t
join album al
	on t.albumid = al.albumid
join artist ar
	on al.artistid = ar.artistid
join genre g
	on t.genreid = g.genreid
where not exists (
					select * 
					from invoiceline il
					where t.trackid = il.trackid
					);


--10) Find artist who have performed in multiple genres. Diplay the aritst name and the genre.

-- Solution 1:
with cte1 as (
	select distinct(g.name) as genre, ar.name as artist
	from track t
	join genre g
		on t.genreid = g.genreid
	join album al
		on t.albumid = al.albumid
	join artist ar
		on al.artistid = ar.artistid
	),
	cte2 as (
		select *, row_number() over(partition by artist) as count 
		from cte1
		),
	cte3 as (
		select *, sum(count) over(partition by artist) 
		from cte2
		)
select artist, genre, count 
from cte3 
where sum > 1
order by artist;

-- Solution 2:
with cte as (
	select distinct(g.name) as genre, ar.name as artist
	from track t
	join genre g
		on t.genreid = g.genreid
	join album al
		on t.albumid = al.albumid
	join artist ar
		on al.artistid = ar.artistid
	)
select c.artist, genre
from (
	select artist 
	from cte
	group by artist
		having count(1) > 1
	) x join cte c on c.artist = x.artist
order by 1;
	

--11) Which is the most popular and least popular genre?

-- Solution 1:
with cte as (
	select 
		g.name as genre, 
		count(distinct(c.customerid)) as no_of_listeners, 
		max(count(distinct(c.customerid))) over(), 
		min(count(distinct(c.customerid))) over()
	from customer c
	join invoice i
		on c.customerid = i.customerid
	join invoiceline il
		on i.invoiceid = il.invoiceid
	join track t
		on il.trackid = t.trackid
	join genre g
		on t.genreid = g.genreid
	group by genre
	)
select genre, no_of_listeners, case when no_of_listeners = max then 'Most Popular' else 'Least Popular' end as popularity
from cte
where no_of_listeners = max or no_of_listeners = min;

-- Solution 2:
with cte as (
	select 
		g.name as genre, 
		count(distinct(c.customerid)) as no_of_listeners, 
		dense_rank() over(order by count(distinct(c.customerid)) desc) as rank,
		min(count(distinct(c.customerid))) over() as min_value
	from customer c
	join invoice i
		on c.customerid = i.customerid
	join invoiceline il
		on i.invoiceid = il.invoiceid
	join track t
		on il.trackid = t.trackid
	join genre g
		on t.genreid = g.genreid
	group by genre
	)
select genre, no_of_listeners, case when rank = 1 then 'Most Popular' else 'Least Popular' end as popularity
from cte
where rank = 1 or no_of_listeners = min_value;


/*12) Identify if there are tracks more expensive than others. If there are then display the track name along with the album 
title and artist name for these expensive tracks.*/

select t.name as track, title as album, ar.name as artist, unitprice
from track t
join album al
	on t.albumid = al.albumid
join artist ar
	on al.artistid = ar.artistid
where unitprice > (select min(unitprice) from track);


/*13) Identify the 5 most popular artist for the most popular genre.
Popularity is defined based on how many songs an artist has performed in for the particular genre.
Display the artist name along with the no of songs.
[Reason: Now that we know that our customers love rock music, we can decide which musicians to invite to play at the concert.
Lets invite the artists who have written the most rock music in our dataset.]*/

with cte as (
	select 
		ar.name as artist, 
		count(distinct(trackid)) as no_of_songs,
		dense_rank() over(order by count(distinct(trackid)) desc) as rank
	from artist ar
	join album al
		on ar.artistid = al.artistid
	join track t
		on al.albumid = t.albumid
	join genre g
		on t.genreid = g.genreid
	where g.name in (
					select genre from (
							select 
								g.name as genre, 
								count(distinct(c.customerid)) as no_of_listeners, 
								dense_rank() over(order by count(distinct(c.customerid)) desc) as rank
							from customer c
							join invoice i
								on c.customerid = i.customerid
							join invoiceline il
								on i.invoiceid = il.invoiceid
							join track t
								on il.trackid = t.trackid
							join genre g
								on t.genreid = g.genreid
							group by genre
							) x where rank = 1
					)
	group by artist
	)
select * from cte where rank <= 5;


--14) Find the artist who has contributed with the maximum no of songs/tracks. Display the artist name and the no of songs.

with cte as (
	select 
		ar.name as artist, 
		count(distinct(trackid)) as no_of_songs, 
		dense_rank() over(order by count(distinct(trackid)) desc) as rank
	from artist ar
	join album al
		on ar.artistid = al.artistid
	join track t
		on al.albumid = t.albumid
	group by artist
	)
select artist, no_of_songs from cte where rank = 1;


--15) Are there any albums owned by multiple artist?

select title as album, count(distinct(ar.artistid)) as no_of_artists
from artist ar
join album al
	on ar.artistid = al.artistid
group by album
	having count(distinct(ar.artistid)) > 1;
 
--16) Is there any invoice which is issued to a non existing customer?

select * from invoice i
where not exists (
					select * from customer c
					where c.customerid = i.customerid
					);


--17) Is there any invoice line for a non existing invoice?

select * from invoiceline il
where not exists (
					select * from invoice i
					where i.invoiceid = il.invoiceid
					);
					

--18) Are there albums without a title?

select * from album where title is null;


--19) Are there invalid tracks in the playlist?

select * from playlisttrack pt
where not exists (
					select * from track t
					where t.trackid = pt.trackid
					);

