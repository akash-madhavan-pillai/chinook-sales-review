-- ============================================================
-- 01_customer_concentration.sql
-- Q1: How concentrated is our customer revenue?
-- Stakeholder: Head of Sales
-- Run after 00_validation.sql (all checks passed).
-- ============================================================


-- Q1a: Lifetime spend per customer, highest first
-- Finding: range is narrow, $36.64 to $49.62.
select c.firstname, c.lastname, c.country, sum(i.total) as total_spent
from customer c
join invoice i on c.customerid = i.customerid
group by c.customerid, c.firstname, c.lastname, c.country
order by total_spent desc;

-- Q1b: Combined revenue share of the top 10 customers
-- Finding: 19.38% (top 17% of customers). Far below a typical 80/20 pattern.
-- LIMIT sits inside the subquery so only the top 10 are summed.

select round(sum(customer_total)*100
	/(select sum(total)from invoice),2)top10_revenue_share_pct
from (
select customerid,sum(total)customer_total
from invoice
group by customerid
order by sum(total) desc
limit 10
)top_10_picks;


-- Q1c: Each customer's individual share of revenue (top 10)
-- Finding: largest customer = 2.13%. Even share would be 1.69% (1/59).
-- Reconciles with Q1b: top 10 individual shares sum to 19.37%.

select c.firstname,c.lastname,round
	(sum(i.total)*100
	/(select sum(total)from invoice),2)revenue_concentration
from customer c 
join invoice i on c.customerid = i.customerid
group by c.customerid, c.firstname,c.lastname
order by revenue_concentration desc
limit 10;

-- Q1d: Revenue and customers by country
-- COUNT(DISTINCT) because the join repeats each customer once per invoice.
-- Finding: USA = 22.46% of revenue from 13 customers; 15 countries have 1 customer.

select c.country,count(distinct c.customerid)customer_count,sum(i.total)country_total,round(
	 sum(i.total) * 100 / (select sum(total)from invoice),2)revenue_shares
from customer c
join invoice i on c.customerid = i.customerid
group by c.country
order by country_total desc;

-- Q1e: Average spend per customer by country (top 10)
-- Finding: USA ranks 8th ($40.24) despite leading on total revenue.
-- Caveat: top 3 countries have only 1 customer each (small samples).

select c.country, round(sum(i.total)/count(distinct c.customerid),2)avg_spend_per_customer
from customer c 
join invoice i on c.customerid = i.customerid
group by c.country
order by avg_spend_per_customer desc
limit 10;


