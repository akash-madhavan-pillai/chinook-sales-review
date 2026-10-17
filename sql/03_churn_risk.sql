-- ============================================================
-- 03_churn_risk.sql
-- Q3: Which customers are at risk of churning,
--     and which of them are worth saving?
-- Stakeholder: Head of Sales + Marketing
-- Reference date = last invoice in the data (2013-12-22),
-- not today's date, because the data ends in 2013.
-- ============================================================

-- Q3a-i: Reference date ("today" for this dataset)
-- Finding: 2013-12-22.
select max(invoicedate)::date as reference_date
from invoice;

-- Q3a: Recency - days since each customer's last purchase
-- ::date on both sides so subtraction gives whole days.
-- Finding: ranges from 0 (Manoj Pareek) to 571 days (Puja Srivastava).
select c.firstname,c.lastname,c.country,max(i.invoicedate)::date as last_purchase,
(select max(invoicedate)::date from invoice ) - max(i.invoicedate)::date as days_since_last 
from customer c
join invoice i on c.customerid = i.customerid
group by c.customerid,c.firstname,c.lastname,c.country
order by max(i.invoicedate)::date;

-- Q3b: Purchase frequency and average gap between purchases
-- avg gap = (last - first) / (count - 1.0); 1.0 avoids integer division.
-- Finding: every customer made 7 purchases except Puja Srivastava (6).
-- Average gaps take only ~6 values (207-298 days) - a sign of synthetic data.
select c.firstname,c.lastname,min(i.invoicedate)::date as first_purchase,max(i.invoicedate)::date as last_purchase,
count(i.invoiceid)purchase_count,
round(((max(i.invoicedate)::date-min(i.invoicedate)::date)/
	(count(i.invoiceid)-1.0)),2)avg_gap_days
from customer c 
join invoice i on c.customerid = i.customerid 
group by c.customerid,c.firstname,c.lastname
order by avg_gap_days desc;

-- Q3c: Customer value and how overdue they are
-- overdue_ratio = days since last purchase / their own average gap
-- (above 1 = past their usual gap; 2+ = missed two whole cycles).
-- Inner query builds the metrics; outer query reuses the aliases.
-- Finding: 23 customers are overdue (ratio > 1); 10 have missed 2+ cycles.
select first_name,last_name,lifetime_value,days_since_last,avg_gap_date,round(days_since_last/avg_gap_date,2)overdue_ratio
from
(select c.firstname as first_name,
c.lastname as last_name,
sum(i.total)lifetime_value,
(select max(invoicedate)::date from invoice ) - max(i.invoicedate)::date as days_since_last,
round((max(i.invoicedate)::date - min(i.invoicedate)::date) /
	(count(i.invoiceid)-1.0),2)avg_gap_date
from customer c 
join invoice i on c.customerid = i.customerid
group by c.customerid,c.firstname,c.lastname)as metrics
order by overdue_ratio desc;


-- Q3d: Customer segments by churn risk and value
-- At risk   = overdue_ratio > 1 (past their usual purchase gap)
-- High value = lifetime value above the average customer ($39.47)
-- CTE "metrics" builds per-customer numbers; CASE assigns the segment.
-- Finding: Save 6, Nurture 16, Let go 17, Monitor 20 (total 59).
with metrics as (select c.firstname as first_name,
	c.lastname as last_name,
	sum(i.total)lifetime_value,
	(select max(invoicedate)::date from invoice ) - max(i.invoicedate)::date as days_since_last,
	round((max(i.invoicedate)::date - min(i.invoicedate)::date) /
		(count(i.invoiceid)-1.0),2)avg_gap_date
	from customer c 
	join invoice i on c.customerid = i.customerid
	group by c.customerid,c.firstname,c.lastname)
	
select first_name,last_name,lifetime_value,
round(days_since_last/avg_gap_date,2)overdue_ratio,
case
	when days_since_last/avg_gap_date > 1
	and lifetime_value > (select avg(lifetime_value)from metrics) then 'Save'
	when days_since_last/avg_gap_date > 1 then 'Let go'
	when lifetime_value > (select avg(lifetime_value)from metrics) then 'Nurture'
	else 'Monitor'
	end as segment 
from metrics
order by segment, overdue_ratio desc;

-- Q3e: Customer value by segment, with a grand total (ROLLUP)
-- Two chained CTEs: metrics -> segmented -> summary.
-- Check: Total row = 59 customers, $2,328.60, 100%.
-- Finding: overdue customers (Save + Let go) = 23, holding $900.28 (38.66%)
-- of lifetime value. Save alone = 6 customers, $257.72 (11.07%).
-- Note: lifetime value is past spend, i.e. value at risk, not guaranteed revenue.
with metrics as (select c.firstname as first_name,
	c.lastname as last_name,
	sum(i.total)lifetime_value,
	(select max(invoicedate)::date from invoice ) - max(i.invoicedate)::date as days_since_last,
	round((max(i.invoicedate)::date - min(i.invoicedate)::date) /
		(count(i.invoiceid)-1.0),2)avg_gap_date
	from customer c 
	join invoice i on c.customerid = i.customerid
	group by c.customerid,c.firstname,c.lastname)
,
segmented as (select first_name,last_name,lifetime_value,
	round(days_since_last/avg_gap_date,2)overdue_ratio,
	case
		when days_since_last/avg_gap_date > 1
		and lifetime_value > (select avg(lifetime_value)from metrics) then 'Save'
		when days_since_last/avg_gap_date > 1 then 'Let go'
		when lifetime_value > (select avg(lifetime_value)from metrics) then 'Nurture'
		else 'Monitor'
		end as segment 
	from metrics)
select coalesce(segment,'Total')segment, count(*)customers,
sum(lifetime_value)total_value,
round((sum(lifetime_value)*100.0/(select sum(total)from invoice)),2)value_share_pct
from segmented
group by rollup(segment )
order by grouping(segment), total_value desc;