;with expand(Startdate,EndDate,UniqueAccountid, MRR,CurrDate) As --This code recursively generate monthly revenues for each contract and puts the date as 01 for every contract
(

	SELECT c.*, cast(concat(left(cast([Contract_Start_Date] as date),7),'-01') as date) FROM [dbo].[Contractsdata] AS c
	UNION ALL
       SELECT StartDate, EndDate, UniqueAccountid, MRR, DATEADD(month, 1, CurrDate) FROM expand
        WHERE CurrDate < EndDate
)


,step0 as  -- This code sums the revenues per account per months and also fetches the count of unique account id(how many times it repeated per month)
(
	select UniqueAccountid,sum(MRR) as MRR, CurrDate, count(*) as n
	from expand
	group by UniqueAccountid,CurrDate
)

,step1 as   -- This code tells previous 12 months MRR and after 12 months MRR  for particular uniqueaccountid
(
	select *,
	LAG(MRR,12) over (PARTITION BY UniqueAccountid order by CurrDate) as LYMRR
	,LEAD(MRR, 12) OVER (PARTITION BY UniqueAccountid ORDER BY CurrDate) AS MRR2
	from step0 
	)

,step2 as  --This code combines data of Last Year MRR detail with rows representing accounts with no further contracts(410943 rows)
(
select UniqueAccountid, MRR,CurrDate,n,LYMRR from step1
union all
select UniqueAccountid,MRR2 as MRR, Dateadd(year,1,CurrDate) as CurrDate, 0 as n, MRR as LYMRR
from step1
where MRR2 is null  --This adds the records to the table where MRR2 is null 
)

,step3 as(		--This code calculates upsell,downsell,newsell,churn(410943 rows)
select UniqueAccountid,MRR,CurrDate,n,LYMRR,
case when MRR>LYMRR then MRR-LYMRR end as upsell,
case when MRR<LYMRR then MRR-LYMRR end as downsell,
case when LYMRR is null then MRR end as newsell,
case when MRR IS NULL THEN LYMRR END AS churn
from step2
)
-- This below code sums the revenue per month and inserts in dbo.revenue_month table
insert into [dbo].[revenue_month]([Month],[MRR],[Upsell],[Downsell],[Newsell],[Churn],[Revenue_12_months_ago],[Revenue_this_month])
select rev1.month1,rev1.MRR,rev1.upsell,rev1.downsell,rev1.newsell,rev1.churn,rev1.Revenue_12_months_ago,
coalesce(rev1.upsell,0)+coalesce(rev1.downsell,0)+coalesce(rev1.newsell,0)+coalesce(rev1.churn,0)+coalesce(rev1.Revenue_12_months_ago,0) as [Revenue_this_month] from
(select rev.month1,rev.MRR,rev.upsell,rev.downsell,rev.newsell,rev.churn,
lag(rev.MRR,12) over(ORDER BY rev.month1 ) AS Revenue_12_months_ago from
(SELECT 
	  cast(concat(left(CurrDate ,7),'-01') as date) month1
     ,	SUM(MRR)      AS MRR
     , SUM(upsell)   AS Upsell
     , SUM(downsell) AS Downsell
     , SUM(newsell)  AS Newsell
     , SUM(-churn)    AS Churn
  FROM step3
 GROUP BY CurrDate
 ORDER BY CurrDate
 offset 0 rows)rev)
 rev1
 



delete from  [dbo].[revenue_month]
select *from [dbo].[revenue_month] order by MONTH












