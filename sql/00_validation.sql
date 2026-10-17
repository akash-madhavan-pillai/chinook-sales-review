-- ============================================================
-- 00_validation.sql
-- Chinook Music Store - Data Quality Validation
--
-- Run FIRST, before any analysis in 01_*.sql onwards.
-- Six layers: row counts, PK uniqueness, FK integrity,
-- blank audit, value ranges, revenue reconciliation.
-- All layers passed on initial load.
-- Schema discovery queries live in scratchpad.sql.
-- ============================================================


-- ============================================================
-- LAYER 1: Row counts
-- Purpose: confirm every table loaded and holds expected data.
-- Expected counts baselined against source: Chinook_PostgreSql.sql
-- ============================================================

select 'album' as table_name , count(*)row_count  from album
union all
select 'artist' , count(*)  from artist
union all
select 'customer' , count(*)  from customer
union all
select 'employee', count(*) from employee
union all
select 'genre', count(*)  from genre
union all
select 'invoice', count(*)  from invoice
union all
select 'invoiceline', count(*)  from invoiceline
union all
select 'mediatype' , count(*)  from mediatype
union all
select 'playlist', count(*) from playlist
union all
select 'playlisttrack', count(*)  from playlisttrack
union all
select 'track', count(*)  from track
order by row_count desc;


 




-- ============================================================
-- LAYER 2: Primary key uniqueness
-- Purpose: confirm every ID column is unique and non-null.
-- Pass condition: every duplicate_count = 0.
-- ============================================================


select 'album'as table_name,count(*),count(distinct albumid)distinct_ids, count(*)-count(distinct albumid)duplicate_count
 from album 
 union all 
 select 'artist' ,count(*),count(distinct artistid),count(*)-count(distinct artistid)
 from artist
 union all 
 select 'customer' ,count(*),count(distinct customerid),count(*)-count(distinct customerid)
 from customer
 union all 
 select 'employee' ,count(*),count(distinct employeeid),count(*)-count(distinct employeeid)
 from employee
 union all 
 select 'genre' ,count(*),count(distinct genreid),count(*)-count(distinct genreid)
 from genre
 union all 
 select 'invoice' ,count(*),count(distinct invoiceid),count(*)-count(distinct invoiceid)
 from invoice
 union all 
 select 'invoiceline' ,count(*),count(distinct invoicelineid),count(*)-count(distinct invoicelineid)
 from invoiceline
 union all 
 select 'mediatype' ,count(*),count(distinct mediatypeid),count(*)-count(distinct mediatypeid)
 from mediatype
 union all 
 select 'playlist' ,count(*),count(distinct playlistid),count(*)-count(distinct playlistid)
 from playlist
 union all 
 select 'track',count(*),count(distinct trackid),count(*)-count(distinct trackid)
 from track;

select 'playlisttrack (composite) ' as check_name, 
count(*)row_count,count(distinct(playlistid,trackid))distinct_pairs,
count(*)- count(distinct(playlistid,trackid))duplicate_pairs
from playlisttrack;









-- ============================================================
-- LAYER 3: Foreign key integrity
-- Purpose: confirm every FK points to a real parent row.
-- Pass condition: every orphan_count = 0.
-- Note: nullable FKs (customer.supportrepid, employee.reportsto,
-- track.albumid, track.genreid) use IS NOT NULL guards
-- to avoid counting legitimate NULLs as orphans.
-- ============================================================





select 'invoice -> customer' as relationship, count(*)orphan_count
from invoice i
left join customer c on i.customerid = c.customerid
where c.customerid is null

union all
select 'album -> artist',count(*)
from album al 
left join artist a on al.artistid = a.artistid 
where a.artistid is null 

union all
select 'customer -> employee',count(*)
from customer c 
left join employee e on c.supportrepid = e.employeeid
where c.supportrepid is not null and e.employeeid is null


union all 
select 'employee -> reportsto', count(*)
from employee e
left join employee e1 on e.reportsto = e1.employeeid
where e1.employeeid is null and e.reportsto is not null


union all 
select 'invoiceline -> invoice', count(*)
from invoiceline il
left join invoice i on il.invoiceid = i.invoiceid
where i.invoiceid is null


union all 
select 'invoiceline -> track', count(*)
from invoiceline il 
left join track t on il.trackid = t.trackid
where t.trackid is null


union all 
select 'playlisttrack -> playlist', count(*)
from playlisttrack pl
left join playlist p on pl.playlistid = p.playlistid
where p.playlistid is null


union all 
select 'playlisttrack -> track', count(*)
from playlisttrack pl
left join track t on pl.trackid = t.trackid
where t.trackid is null


union all 
select 'track -> album', count(*)
from track t
left join album a on t.albumid = a.albumid
where a.albumid is null and t.albumid is not null


union all 
select 'track -> genre', count(*)
from track t
left join genre g on t.genreid =g.genreid
where g.genreid is null and t.genreid is not null

union all 
select 'track -> mediatype', count(*)
from track t
left join mediatype m on t.mediatypeid = m.mediatypeid
where m.mediatypeid is null;


-- ============================================================
-- LAYER 4: Blank (NULL) audit on analysis-critical columns
-- Purpose: confirm columns used by Q1-Q3 have no missing values.
-- Expected: 0 blanks on all except track.composer
-- (control column, not used in analysis).
-- ============================================================


select 'track'as table_name,'composer'as column_checked, count(*)total_count,count(composer)filled_in,count(*)-count(composer)blank_count
from track

union all
select 'customer','country', count(*),count(country),count(*)-count(country)
from customer 

union all
select 'customer','supportrepid', count(*),count(supportrepid),count(*)-count(supportrepid)
from customer 


union all
select 'invoice' ,'billingcountry', count(*),count(billingcountry),count(*)-count(billingcountry)
from invoice

union all
select 'track','albumid', count(*),count(albumid),count(*)-count(albumid)
from track

union all
select 'track','genreid', count(*),count(genreid),count(*)-count(genreid)
from track
order by table_name;


-- ============================================================
-- LAYER 5: Value ranges
-- Purpose: confirm numeric and date columns hold sensible values
-- (no negatives, no zero-value invoices, no impossible dates).
-- Dates shown as year via EXTRACT so all rows share a numeric type.
-- ============================================================

select 'track.unitprice'as column_checked,
min(unitprice)min_value,
max(unitprice)max_value
from track 

union all 

select 'track.milliseconds',
min(milliseconds),
max(milliseconds)
from track 


union all 
select 'invoiceline.unitprice',
min(unitprice),
max (unitprice)
from invoiceline

union all 
select 'invoiceline.quantity',
min(quantity),
max (quantity)
from invoiceline

union all 
select 'invoice.total',
min(total),
max(total)
from invoice 


union all
select 'invoice.invoicedate (year)',
extract(year from min(invoicedate)),
extract(year from max(invoicedate))
from invoice 
order by column_checked;



-- ============================================================
-- LAYER 6: Business-logic reconciliation
-- Purpose: revenue calculated two ways must agree.
-- 6a: grand total (invoice headers vs invoice lines)
-- 6b: per invoice - catches offsetting errors a total match can hide
-- Pass condition: 6a totals equal; 6b returns zero rows.
-- ============================================================

select 'from invoice header ' as method, sum(total)
from invoice
union all
select 'from invoiceline line', sum(unitprice*quantity)
from invoiceline;

select i.invoiceid,i.total,sum(il.unitprice*il.quantity)line_total
from invoice i
join invoiceline il on i.invoiceid = il.invoiceid 
group by i.invoiceid,i.total
having  sum(il.unitprice*il.quantity) <> i.total;