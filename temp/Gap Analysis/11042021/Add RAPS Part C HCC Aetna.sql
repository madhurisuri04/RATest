/**********************************************************************************
Get Source Gap data and populate it into temp ProdSupport table
**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_AetnaTest_GAP_Diags_Add 

select 
	left(DOSEnd, 4) as DOS_year,
	MemberNumber as MBI,
	FinalMemberNumber as HICN,
	DiagnosisCode,
	DOSStart,
	DOSEnd,
	ProviderType
into ProdSupport.dbo.tbl_AetnaTest_GAP_Diags_Add 
from ProdSupport.dbo.hst_AETGapCheck_000a_Source
where RunID = 9 and Status = 'A'

drop table #MMR
select distinct m.HICN, m.PartCRAFTProjected RAFactorType, m.PlanID
into #MMR
from 
	[Aetna_Report].[rev].[tbl_Summary_RskAdj_MMR] m,
	ProdSupport.dbo.hst_AETGapCheck_000a_Source a
where 
	RunID = 9
	and a.FinalMemberNumber = m.hicn
	and m.PaymentYear = 2020

insert into #MMR
select distinct m.HICN, m.PartCRAFTProjected RAFactorType, m.PlanID
from 
	[AetIH_Report].[rev].[tbl_Summary_RskAdj_MMR] m,
	ProdSupport.dbo.hst_AETGapCheck_000a_Source a
where 
	RunID = 9
	and a.FinalMemberNumber = m.hicn
	and m.PaymentYear = 2020

/**********************************************************************************
Diag HCC Mapping for 2020 PY
Use 2018 Model Year for RAPS
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
	B.Payment_Year in (2018) 
	and b.Factor_Type not in ('E','E1','E2','SE','ED')

select * from #Diag_HCC_Lookup


/**********************************************************************************
Create ALL Diag table for population members and check eligibility with MMR

Use already created RAPS Source table  - ProdSupport.[HRP\hasan.farooqui].AETGapCheck_002d_RAPS_Source
Use already created MMR Source table - ProdSupport.[HRP\hasan.farooqui].AETGapCheck_002a_MMR

**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_GAP_All_Diags_RAPS_PartC_AetnaTest


/**********************************************************************************
Insert all diagnoses from RAPS Source table 
**********************************************************************************/


-- truncate table ProdSupport.dbo.tbl_GAP_All_Diags_RAPS_PartC_AetnaTest

-- insert into ProdSupport.dbo.tbl_GAP_All_Diags_RAPS_PartC_AetnaTest
select distinct 
	EncounterSource = 'RAPS', 
	PaymentYear = YEAR(ThruDate) + 1, 
	a.HICN HICN, 
	FromDate, 
	ThruDate, 
	DiagnosisCode, 
	ProviderType,
	HCC = lk.HCC_Label,
	'N' IsAdded,
	m.RAFactorType,
	m.PlanID
--into ProdSupport.dbo.tbl_GAP_All_Diags_RAPS_PartC_AetnaTest
from [Aetna_Report].dbo.raps_diagHCC_Rollup a
	inner join #MMR m
	on a.HICN = m.hicn
	left join #Diag_HCC_Lookup lk
	on a.DiagnosisCode = lk.ICD10CD
    AND lk.Payment_Year = 2018
	and m.RAFactorType = lk.Factor_Type
where YEAR(Thrudate) = 2019 
	and Accepted = 1 
	and Deleted is null
	and a.HICN in (select HICN from ProdSupport.dbo.tbl_AetnaTest_GAP_Diags_Add)

insert into ProdSupport.dbo.tbl_GAP_All_Diags_RAPS_PartC_AetnaTest
select distinct 
	EncounterSource = 'RAPS', 
	PaymentYear = YEAR(ThruDate) + 1, 
	a.HICN HICN, 
	FromDate, 
	ThruDate, 
	DiagnosisCode, 
	ProviderType,
	HCC = lk.HCC_Label,
	'N' IsAdded,
	m.RAFactorType,
	m.PlanID
from [AetIH_Report].dbo.raps_diagHCC_Rollup a
	inner join #MMR m
	on a.HICN = m.hicn
	left join #Diag_HCC_Lookup lk
	on a.DiagnosisCode = lk.ICD10CD
    AND lk.Payment_Year = 2018
	and m.RAFactorType = lk.Factor_Type
where YEAR(Thrudate) = 2019 
	and Accepted = 1 
	and Deleted is null
	and a.HICN in (select HICN from ProdSupport.dbo.tbl_AetnaTest_GAP_Diags_Add)
/**********************************************************************************
insert all Add diagnoses from Extract file
**********************************************************************************/

insert into ProdSupport.dbo.tbl_GAP_All_Diags_RAPS_PartC_AetnaTest
select distinct 
	'RAPS', 
	YEAR(DOSEnd) + 1, 	
	a.HICN, 
	DOSStart, 
	DOSEnd, 
	DiagnosisCode,
	ProviderType,
	HCC = lk.HCC_Label,
	'Y' as IsAdded,
	m.RAFactorType,
	m.PlanID
from 
	ProdSupport.dbo.tbl_AetnaTest_GAP_Diags_Add a 
	inner join #MMR m
	on a.HICN = m.HICN
	left join #Diag_HCC_Lookup lk
	on a.DiagnosisCode = lk.ICD10CD
    AND lk.Payment_Year = 2018
	and m.RAFactorType = lk.Factor_Type
where a.DOS_year = 2019 


/**********************************************************************************
Get all New HCC that do not exist in current diag list
**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_RAPS_PartC_AetnaTest

--truncate table ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_RAPS_PartC_AetnaTest

--insert into ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_RAPS_PartC_AetnaTest
select distinct 
	PaymentYear, 
	HICN, 
	HCC, 
	Hierarchy = CAST(NULL as varchar(1)), 
	HeirHCC = CAST(NULL as varchar(10)), 
	PlanID,
	RAFactorType
--into ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_RAPS_PartC_AetnaTest
from 
	ProdSupport.dbo.tbl_GAP_All_Diags_RAPS_PartC_AetnaTest
where 
	HCC is not null 
	and IsAdded = 'Y'
Except
select distinct 
	PaymentYear, 
	HICN, 
	HCC, 
	NULL, 
	NULL,
	PlanID,
	RAFactorType
from 
	ProdSupport.dbo.tbl_GAP_All_Diags_RAPS_PartC_AetnaTest
where 
	HCC is not null 
	and IsAdded = 'N'


/**********************************************************************************
Apply Hierarchy
**********************************************************************************/

UPDATE A
SET Hierarchy = 'L'
FROM ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_RAPS_PartC_AetnaTest A
WHERE 
	EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_GAP_All_Diags_RAPS_PartC_AetnaTest B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND B.HCC = C.HCC_KEEP
               AND A.HCC = C.HCC_DROP
               AND C.Payment_Year = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
        where IsAdded = 'N'
	)

UPDATE A
SET Hierarchy = 'L'
FROM ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_RAPS_PartC_AetnaTest A
WHERE 
	EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_RAPS_PartC_AetnaTest B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND B.HCC = C.HCC_KEEP
               AND A.HCC = C.HCC_DROP
               AND C.Payment_Year = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
	)

UPDATE A
SET Hierarchy = 'H'
FROM ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_RAPS_PartC_AetnaTest A
WHERE Hierarchy is null
AND	EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_GAP_All_Diags_RAPS_PartC_AetnaTest B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND A.HCC = C.HCC_KEEP
               AND B.HCC = C.HCC_DROP
               AND C.Payment_Year = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
        where IsAdded = 'N'
	)

drop table if exists #HierHCC

select distinct a.PaymentYear, a.HICN, a.HCC, b.HCC HierHCC, RANK() over (partition by a.hicn, a.hcc order by b.hcc) rnk
into #HierHCC
from 
      ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_RAPS_PartC_AetnaTest a
      join ProdSupport.dbo.tbl_GAP_All_Diags_RAPS_PartC_AetnaTest b
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
	a.HeirHCC = b.HierHCC
from ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_RAPS_PartC_AetnaTest a
join #HierHCC b
on a.HICN = b.HICN
and a.HCC = b.HCC
and a.PaymentYear = b.PaymentYear
and b.rnk = 1

/**********************************************************************************
Final list of New HCC after filtering out lower Hierarchy HCC
Final New HCC table - ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest
**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest

--truncate table ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest

--insert into ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest
select distinct
	a.PaymentYear, 
	a.HICN, 
	a.HCC, 
	a.HeirHCC
--into ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest
from
	ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_RAPS_PartC_AetnaTest a
Where
	a.Hierarchy is NULL or a.Hierarchy = 'H'


/**********************************************************************************
Add Interaction 
**********************************************************************************/

drop table if exists #tbl_GAP_All_HCC_RAPS_PartC_AetnaTest

select distinct PaymentYear, HICN, HCC, RAFactorType, IsAdded 
into #tbl_GAP_All_HCC_RAPS_PartC_AetnaTest
from ProdSupport.dbo.tbl_GAP_All_Diags_RAPS_PartC_AetnaTest
where HCC is not null

-- Interaction before Newly added HCC
drop table if exists #tbl_GAP_All_INT_RAPS_PartC_AetnaTest

select distinct
	a.PaymentYear,
	a.HICN,
	i.Interaction_Label HCC,
	a.RAFactorType
into #tbl_GAP_All_INT_RAPS_PartC_AetnaTest
from 
	HRPReporting.dbo.lk_Risk_Models_Interactions i
	join #tbl_GAP_All_HCC_RAPS_PartC_AetnaTest a
	on	a.RAFactorType = i.Factor_Type
	and a.HCC = i.HCC_Label_1
	join #tbl_GAP_All_HCC_RAPS_PartC_AetnaTest b
	on	b.RAFactorType = i.Factor_Type
	and b.HCC = i.HCC_Label_2
	and a.HICN = b.HICN
	join #tbl_GAP_All_HCC_RAPS_PartC_AetnaTest c
	on  c.RAFactorType = i.Factor_Type
	and c.HCC = i.HCC_Label_3
	and a.HICN = c.HICN
	and b.HICN = c.HICN
where i.Payment_Year = 2018
	and a.IsAdded = 'N'
	and b.IsAdded = 'N'
	and c.IsAdded = 'N'

-- Interaction after Newly added HCC

drop table if exists #tbl_GAP_NEW_INT_RAPS_PartC_AetnaTest

select distinct
	a.PaymentYear,
	a.HICN,
	i.Interaction_Label HCC,
	a.RAFactorType
into #tbl_GAP_NEW_INT_RAPS_PartC_AetnaTest
from 
	HRPReporting.dbo.lk_Risk_Models_Interactions i
	join #tbl_GAP_All_HCC_RAPS_PartC_AetnaTest a
	on	a.RAFactorType = i.Factor_Type
	and a.HCC = i.HCC_Label_1
	join #tbl_GAP_All_HCC_RAPS_PartC_AetnaTest b
	on	b.RAFactorType = i.Factor_Type
	and b.HCC = i.HCC_Label_2
	and a.HICN = b.HICN
	join #tbl_GAP_All_HCC_RAPS_PartC_AetnaTest c
	on  c.RAFactorType = i.Factor_Type
	and c.HCC = i.HCC_Label_3
	and a.HICN = c.HICN
	and b.HICN = c.HICN
where i.Payment_Year = 2018

/**********************************************************************************
New Interaction triggered by New HCC
**********************************************************************************/
insert into ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest
select distinct 
	PaymentYear,
	HICN,
	HCC,
	NULL HeirHCC
from
(
select PaymentYear, HICN, HCC from #tbl_GAP_NEW_INT_RAPS_PartC_AetnaTest
except
select PaymentYear, HICN, HCC from #tbl_GAP_All_INT_RAPS_PartC_AetnaTest
) a

/**********************************************************************************
 Final list of New HCC with Intaction
 The records with Non NULL HierHCC means they are partially impacted
**********************************************************************************/

select * from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest

alter table ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest add HCC_Number int

update ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest
set HCC_Number = cast (LTRIM(REVERSE(LEFT(REVERSE(hcc), PATINDEX('%[A-Z]%',REVERSE(hcc)) - 1))) as int)












drop table #MOR_RAPS
select distinct hicn, RAFT, factor_description hcc, HCC_Number
into #MOR_RAPS
from Aetna_Report.[rev].[tbl_Summary_RskAdj_MOR]
where paymentYear = 2020
and SubmissionModel = 'RAPS'
and hicn in (select hicn from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest)

insert into #MOR_RAPS
select distinct hicn, RAFT, factor_description hcc, HCC_Number
from AetIH_Report.[rev].[tbl_Summary_RskAdj_MOR]
where paymentYear = 2020
and SubmissionModel = 'RAPS'
and hicn in (select hicn from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest)


select hicn, hcc from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest a
where not exists (select 1 from #mor_raps b where a.hicn = b.hicn and a.hcc = b.hcc)

select hicn, hcc from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest a
where not exists (select 1 from #mor_raps b where a.hicn = b.hicn and a.hcc = b.hcc)
except
Select hicn, hcc from ProdSupport.dbo.hst_AETGapCheck_003a_RAPS_PartC_ADDs where RunID in (9)

Select hicn, hcc from ProdSupport.dbo.hst_AETGapCheck_003a_RAPS_PartC_ADDs where RunID in (9)
except
select hicn, hcc from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest a
where not exists (select 1 from #mor_raps b where a.hicn = b.hicn and a.hcc = b.hcc)

