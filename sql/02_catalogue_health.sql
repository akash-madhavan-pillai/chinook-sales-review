-- ============================================================
-- 02_catalogue_health.sql
-- Q2: What % of the catalogue is dead inventory,
--     and where does revenue actually come from?
-- Stakeholder: Head of Product / Merchandising
-- Run after 00_validation.sql (all checks passed).
-- ============================================================


-- Q2a: Sell-through - how much of the catalogue has ever sold?
-- DISTINCT because the LEFT JOIN repeats a track once per sale.
-- 100.0 (not 100) to avoid integer division.
-- Finding: 1,519 of 3,503 tracks (43.36%) have never sold.
select count(distinct t.trackid)total_tracks,
       count(distinct il.trackid)total_sold,
       count(distinct t.trackid) - count(distinct il.trackid)unsold_track,
       round((count(distinct t.trackid) - count(distinct il.trackid)) * 100.0
             / count(distinct t.trackid), 2)unsold_track_percentage
from track t
left join invoiceline il on t.trackid = il.trackid;


-- Q2a-ii: Why is 43% unsold? Split into two causes.
-- 1) Volume: only 2,240 purchases exist for 3,503 tracks, so at least
--    1,263 tracks (36.05%) would be unsold even if every purchase were different.
-- 2) Repeats: 256 purchases were for tracks already bought (7.31%).
-- 36.05% + 7.31% = 43.36% (reconciles with Q2a).
-- Finding: dead inventory is mainly a volume problem, not a catalogue problem.
select count(distinct t.trackid)total_tracks,
       (select count(*) from invoiceline)total_purchases,
       count(distinct t.trackid) - (select count(*) from invoiceline)unsold_due_to_volume,
       round((count(distinct t.trackid) - (select count(*) from invoiceline)) * 100.0
             / count(distinct t.trackid), 2)volume_pct,
       (select count(*) from invoiceline) - count(distinct il.trackid)repeat_purchases,
       round(((select count(*) from invoiceline) - count(distinct il.trackid)) * 100.0
             / count(distinct t.trackid), 2)repeat_pct
from track t
left join invoiceline il on t.trackid = il.trackid;


-- Q2b: Unsold tracks by genre (count and rate)
-- Check: unsold_track sums to 1,519 (reconciles with Q2a).
-- Finding: Rock has most unsold (552) but an average rate (42.6%).
-- Big four genres sell better than average; most small genres are 50-65% unsold.
-- Exceptions: Bossa Nova 6.7%, Sci Fi & Fantasy 23.1%. Opera = 1 track only.
select g.name as genre,
       count(distinct t.trackid)total_track,
       count(distinct t.trackid) - count(distinct il.trackid)unsold_track,
       round((count(distinct t.trackid) - count(distinct il.trackid)) * 100.0
             / count(distinct t.trackid), 2)unsold_pct
from track t
join genre g on t.genreid = g.genreid
left join invoiceline il on t.trackid = il.trackid
group by g.genreid, g.name
order by unsold_track desc, total_track desc;


-- Q2c: Revenue by genre, with share of total revenue
-- COALESCE turns NULL into 0 for genres with no sales (Opera),
-- so they show $0 and sort to the bottom instead of the top.
-- Finding: Rock = $826.65 (35.5% of revenue).
select g.name  as genre,
       coalesce(sum(il.unitprice * il.quantity), 0)revenue,
       round(coalesce(sum(il.unitprice * il.quantity), 0) * 100.0
             / (select sum(total) from invoice), 2)revenue_share_pct
from track t
join genre g on t.genreid = g.genreid
left join invoiceline il on t.trackid = il.trackid
group by g.genreid, g.name
order by revenue desc;


-- Q2c-ii: Combined revenue share of the top 4 genres
-- LIMIT 4 sits inside the subquery so only the top 4 are summed.
-- Finding: Rock, Latin, Metal, Alternative & Punk = 73.50% of revenue.
-- The other 21 genres share 26.5%.
select sum(revenue_share_pct) as big_four_share_pct
from (
    select g.name,
           round(coalesce(sum(il.unitprice * il.quantity), 0) * 100.0
                 / (select sum(total) from invoice), 2) as revenue_share_pct
    from track t
    join genre g on t.genreid = g.genreid
    left join invoiceline il on t.trackid = il.trackid
    group by g.genreid, g.name
    order by revenue_share_pct desc
    limit 4
) as big_four;


-- Q2d: Fair share - does each genre earn in proportion to its catalogue space?
-- revenue_index = revenue share / track share  (1.0 = fair share)
-- Inner query calculates both shares; outer query reuses the aliases.
-- Finding: big four sit close to 1.0 (Rock 0.96). They are big, not efficient.
-- Top of the index (Sci Fi & Fantasy 2.31, Comedy, TV Shows...) is mostly video.
select genre,
       track_share_pct,
       revenue_share_pct,
       round(revenue_share_pct / track_share_pct, 2) as revenue_index
from (
    select g.name as genre,
           round(count(distinct t.trackid) * 100.0
                 / (select count(*) from track), 2)track_share_pct,
           round(coalesce(sum(il.unitprice * il.quantity), 0) * 100.0
                 / (select sum(total) from invoice), 2)revenue_share_pct
    from track t
    join genre g on t.genreid = g.genreid
    left join invoiceline il on t.trackid = il.trackid
    group by g.genreid, g.name
) as shares
order by revenue_index desc;


-- Q2d-ii: Revenue index by genre AND media type
-- Tests why video genres top Q2d: five of the top six are Protected MPEG-4 video,
-- priced at $1.99 vs $0.99, so each sale earns double.
-- Bossa Nova is the exception: regular audio, still above its share (and 6.7% unsold in Q2b).
-- Note: one row per genre + media type, so some genres appear more than once.
-- Caveat: many rows are tiny (0.03% of tracks), so ignore their index.
select genre,
       media,
       track_share_pct,
       revenue_share_pct,
       round(revenue_share_pct / track_share_pct, 2) as revenue_index
from (
    select g.name as genre,
           m.name as media,
           round(count(distinct t.trackid) * 100.0
                 / (select count(*) from track), 2)track_share_pct,
           round(coalesce(sum(il.unitprice * il.quantity), 0) * 100.0
                 / (select sum(total) from invoice), 2) revenue_share_pct
    from track t
    join genre g on t.genreid = g.genreid
    join mediatype m on t.mediatypeid = m.mediatypeid
    left join invoiceline il on t.trackid = il.trackid
    group by g.genreid, g.name, m.mediatypeid, m.name
) as shares
order by revenue_index desc;