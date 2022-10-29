select sum([MRR(expected)]) as Revenue from [dbo].[Contractsdata]
where [Contract_Start_Date] >='2013-02-01' and [Contract_End_Date]<'2019-12-01'





select month([Contract_Start_Date]) as Active_monthly_contracts, count([MRR(expected)]) as Revenues_count 
from [dbo].[Contractsdata]
where [Contract_Start_Date] between '2013-02-01' and '2019-12-01' and [Contract_End_Date]>'2019-12-01'
group by month([Contract_Start_Date])
order by Active_monthly_contracts




select count(distinct([Unique_Account_Field])) as Revenue_of_Active_accounts from [dbo].[Contractsdata]
where [Contract_Start_Date] between '2013-02-01' and '2019-12-01' and [Contract_End_Date]>'2019-12-01'
and [MRR(expected)]>0



select *from [dbo].[Contractsdata]





