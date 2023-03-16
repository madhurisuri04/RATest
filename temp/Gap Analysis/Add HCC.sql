/**********************************************************************************
Get Source Gap data and populate it into temp prodsupport table
**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_GAP_Diags 

select *, left(from_date, 4) as DOS_year
into ProdSupport.dbo.tbl_GAP_Diags 
from XXX -- table that contains GAP data

/**********************************************************************************
Diag HCC Mapping for 2020 PY
**********************************************************************************/

DROP TABLE IF EXISTS #Diag_HCC_Lookup

Select distinct 
	b.Payment_Year
	,b.Factor_Type
	,b.ICD10CD
	,b.HCC_Label
into 
	#Diag_HCC_Lookup
from
	HRPReporting.dbo.lk_Risk_Models_DiagHCC_ICD10 B  (nolock)  
where  
	B.Payment_Year in (2020) 
	and b.Factor_Type not in ('E','E1','E2','SE','ED')

select * from #Diag_HCC_Lookup


/**********************************************************************************
Combine with MMR
Get enrollment info and only perform analysis for eligible members
**********************************************************************************/

--Get Add Members from MMR
drop table if exists #Temp_SummaryMMR
select * 
	into #Temp_SummaryMMR
from 
	Aetna_report.rev.tbl_Summary_RskAdj_MMR (nolock)
where 
	HICN in (select HICN from ProdSupport.dbo.tbl_GAP_Diags where DOS_year = 2019) -- DOS Year Parameter
	and PaymentYear in (2020) -- Payment Year Parameter


drop table if exists #Temp_MMR1
select 
	PaymentYear, 
	HICN, 
	PartCRaftMMR, 
	max(PaymStart) PaymStart,
	max(PlanID) PlanID, 
	max(PBP) PBP, 
	max(SCC) SCC, 
	count(distinct PaymStart) PaymentMonths,
	cast(0 as int)as Rnk 
into
	#Temp_MMR1
from 
	#Temp_SummaryMMR
where PartCRaftMMR IS NOT NULL
group by 
	PaymentYear, 
	HICN, 
	PartCRaftMMR

drop table if exists #Temp_MMR2
select 
	hicn, 
	max(PaymStart) PaymStart,
	sum(PaymentMonths) PaymentMonths
into #Temp_MMR2
from #Temp_MMR1
group by HICN

update a
set a.rnk = 1
from #Temp_MMR1 a
inner join #Temp_MMR2 b
on a.hicn = b.hicn
and a.paymstart = b.paymstart


/**********************************************************************************
STEP 4: Combine with other HCC records and join with MMR
**********************************************************************************/

--Get all diagnoses from RAPS
drop table if exists ProdSupport.dbo.tbl_GAP_All_Diags

select distinct 
	EncounterSource = 'RAPS', 
	PaymentYear = YEAR(ThruDate) + 1, 
	d.HICN, 
	FromDate, 
	ThruDate, 
	ProviderType, 
	DiagnosisCode, 
	HCC = CAST(NULL as varchar(10)),
	HCCFactor = CAST(NULL as float),
	'N' IsAdded,
	m.PartCRAFTMMR RAFactorType,
	m.PlanID
into ProdSupport.dbo.tbl_GAP_All_Diags
from Aetna_Report.dbo.RAPS_DiagHCC_Rollup d
	inner join #Temp_MMR1 m
	on d.hicn = m.hicn
	and Rnk = 1
	inner join #Temp_MMR2 n
	on d.HICN = n.HICN
where YEAR(d.Thrudate) = 2019 -- DOS Year parameter 
and Accepted = 1 and Deleted is null
and d.HICN in (select HICN from ProdSupport.dbo.tbl_GAP_Diags where DOS_year = 2019) -- DOS Year parameter 


--Add all diagnoses from Adds
insert into ProdSupport.dbo.tbl_GAP_All_Diags
select distinct 
	'RAPS', 
	YEAR(Thru_Date) + 1, 	
	d.HICN, 
	From_Date, 
	Thru_Date, 
	Provd_Type, 
	Diag,
	null as HCC,
	null as HCCFactor,
	'Y' as IsAdded,
	m.PartCRAFTMMR RAFactorType,
	m.PlanID
from 
	ProdSupport.dbo.tbl_GAP_Diags d -- Adds table
	inner join #Temp_MMR1 m
	on d.HICN = m.HICN
	and Rnk = 1
	inner join #Temp_MMR2 n
	on d.HICN = n.HICN
where d.DOS_year = 2019 -- DOS Year parameter 


/**********************************************************************************
Update dgns to HCCS, Apply Heirarchy
filter out what doesn't map to HCC and only keep Add HCC if it is completely new
**********************************************************************************/

--Apply HCC
Update a
set a.HCC = b.HCCLabel, 
	HCCFactor = b.Factor
from ProdSupport.dbo.tbl_GAP_All_Diags a
join #Diag_HCC_Lookup b
	ON A.DiagnosisCode = B.ICDCode
    AND a.PaymentYear = b.PaymentYear
	and a.RAFactorType = b.FactorType


--Get New HCCs generated by Add file
drop table if exists ProdSupport.dbo.tbl_GAP_All_Diags_Hier
select distinct 
	PaymentYear, 
	HICN, 
	HCC, 
	HCCFactor, 
	Hierarchy = CAST(NULL as varchar(1)), 
	HeirHCC = CAST(NULL as varchar(10)), 
	HeirHCCFactor = CAST(NULL as float),
	PlanID,
	RAFactorType
into 
	ProdSupport.dbo.tbl_GAP_All_Diags_Hier
from 
	ProdSupport.dbo.tbl_GAP_All_Diags
where 
	HCC is not null 
	and IsAdded = 'Y'
Except
select distinct 
	PaymentYear, 
	HICN, 
	HCC, 
	HCCFactor, 
	NULL, 
	NULL, 
	NULL,
	PlanID,
	RAFactorType
from 
	ProdSupport.dbo.tbl_GAP_All_Diags
where 
	HCC is not null 
	and IsAdded = 'N'


--Apply Heirarchy

UPDATE A
SET Hierarchy = 'L'
FROM ProdSupport.dbo.tbl_GAP_All_Diags_Hier A
WHERE 
	EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_GAP_All_Diags B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND B.HCC = C.HCC_KEEP
               AND A.HCC = C.HCC_DROP
               AND A.PaymentYear = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
        where IsAdded = 'N'
	)


UPDATE A
SET Hierarchy = 'H'
FROM ProdSupport.dbo.tbl_GAP_All_Diags_Hier A
WHERE Hierarchy is null
AND	EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_GAP_All_Diags B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND A.HCC = C.HCC_KEEP
               AND B.HCC = C.HCC_DROP
               AND A.PaymentYear = B.PaymentYear
               AND C.RA_FACTOR_TYPE = = B.RAFactorType
        where IsAdded = 'N'
	)


drop table #HierHCC

select distinct a.PaymentYear, a.HICN, a.HCC, b.HCC HierHCC, b.HCCFactor HeirHCCFactor, RANK() over (partition by a.hicn, a.hcc order by b.hcc) rnk
into #HierHCC
from 
      ProdSupport.dbo.tbl_GAP_All_Diags_Hier a
      join ProdSupport.dbo.tbl_GAP_All_Diags b
      on a.PaymentYear = b.PaymentYear
      and a.HICN = b.HICN
      join HRPReporting.dbo.lk_Risk_Models_Hierarchy C
      on a.HCC = c.HCC_KEEP
      and b.HCC = c.HCC_DROP
      and b.PaymentYear = c.Payment_Year
      and b.RAFactorType = c.RA_FACTOR_TYPE 
where 
      a.Hierarchy = 'H'


update a
set 
	a.HeirHCC = b.HierHCC, 
	a.HeirHCCFactor = b.HeirHCCFactor
from ProdSupport.dbo.tbl_GAP_All_Diags_Hier a
join #HierHCC b
on a.HICN = b.HICN
and a.HCC = b.HCC
and a.PaymentYear = b.PaymentYear
and b.rnk = 1


/**********************************************************************************

**********************************************************************************/

select	
	a.PaymentYear, 
	a.HICN, 
	a.HCC, 
	a.HCCFactor, 
	a.HeirHCC, 
	a.HeirHCCFactor, 
	AdjustedFactor = isnull(HCCFactor,0) - ISNULL(HeirHCCFactor,0), 
	a.PlanID, 
	a.RAFactorType
from	
	ProdSupport.dbo.tbl_GAP_All_Diags_Hier a
Where
	a.Hierarchy is NULL or a.Hierarchy = 'H'

