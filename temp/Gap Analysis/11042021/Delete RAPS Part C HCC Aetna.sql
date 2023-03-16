/*

After gathering All CMS Accepted Diags, we flag the clusters that match our To-Be-Deleted clusters as ToBeDeleted = 'Y'.
Next,map HCCs to all Diags.
Next,select the HCCs where ToBeDeleted = 'Y' EXCEPT the HCCs where ToBeDeleted is NULL.
Next,Apply Hierarchy = 'L' where ToBeDeleted is NULL population trumps ToBeDeleted = 'Y' population.
Next,Apply Hierarchy = 'H' on remaining Accepted HCCs where ToBeDeleted = 'Y' population trumps ToBeDeleted is NULL population.

*/

/**********************************************************************************
Get Source Gap data and populate it into temp prodsupport table
**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_AetnaTest_GAP_Diags_Delete 

select 
	left(DOSEnd, 4) as DOS_year,
	MemberNumber as MBI,
	FinalMemberNumber as HICN,
	DiagnosisCode,
	DOSStart,
	DOSEnd,
	ProviderType
into ProdSupport.dbo.tbl_AetnaTest_GAP_Diags_Delete 
from ProdSupport.dbo.hst_AETGapCheck_000a_Source
where RunID = 9 and Status = 'D'

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
Create subset of Raps_Diag_HCC_Rollup table containing only members to be deleted
Take only Accepted = 1 so that there are no deletes captured
**********************************************************************************/
/*
select * from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002d_RAPS_Source

select accepted, deleted, count(1) from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002d_RAPS_Source
group by accepted, deleted
*/

drop table if exists ProdSupport.dbo.tbl_Delete_RAPS_DiagHCC_rollup_AetnaTest 

select r.* 
into 
	ProdSupport.dbo.tbl_Delete_RAPS_DiagHCC_rollup_AetnaTest
from 
	[Aetna_Report].dbo.raps_diagHCC_Rollup r
	inner join [Aetna_Report].[rev].[tbl_Summary_RskAdj_MMR] m
	on r.HICN = m.hicn
	and m.PaymentYear = 2020
where YEAR(Thrudate) = 2019
and Accepted = 1
and Deleted is null
and exists (select 1 from ProdSupport.dbo.tbl_AetnaTest_GAP_Diags_Delete d where r.HICN = d.HICN)


/**********************************************************************************
For all matching cluster in the delete list, update Deleted = 'D'
**********************************************************************************/

update b
set 
	Void_Indicator = NULL,
	Voided_By_RAPSID = '9999990',
	Deleted = 'D'
from 
ProdSupport.dbo.tbl_Delete_RAPS_DiagHCC_rollup_AetnaTest (nolock) b
join ProdSupport.dbo.tbl_AetnaTest_GAP_Diags_Delete a
on	a.HICN = b.HICN
and a.DOSStart = b.FromDate
and a.DOSEnd = b.ThruDate
and a.DiagnosisCode = b.DiagnosisCode
and a.ProviderType = b.providerType

/**********************************************************************************
Create a list of all diags with HCC mapping applied
Apply eligibility using MMR
**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_Delete_All_Diags_RAPS_PartC_AetnaTest

select distinct 
	EncounterSource = 'RAPS', 
	PaymentYear = YEAR(ThruDate) + 1, 
	a.HICN, 
	FromDate, 
	ThruDate, 
	ProviderType, 
	DiagnosisCode, 
	HCC = lk.HCC_Label,
	Accepted,
	Deleted,
	Voided_By_RAPSID,
	m.PartCRAFTMMR RAFactorType,
	m.PlanID
into ProdSupport.dbo.tbl_Delete_All_Diags_RAPS_PartC_AetnaTest
from ProdSupport.dbo.tbl_Delete_RAPS_DiagHCC_rollup_AetnaTest a
	inner join [Aetna_Report].[rev].[tbl_Summary_RskAdj_MMR] m
	on a.HICN = m.hicn
	and YEAR(ThruDate) + 1 = m.PaymentYear
	and m.PaymentYear = 2020
	left join #Diag_HCC_Lookup lk
	on a.DiagnosisCode = lk.ICD10CD
    AND lk.Payment_Year = 2018
	and m.PartCRAFTProjected = lk.Factor_Type
where Accepted = 1


select * from ProdSupport.dbo.tbl_Delete_All_Diags_RAPS_PartC_AetnaTest 

/**********************************************************************************
Find the list of HCC triggered by Deleted = D which do not exist elsewhere in the population
**********************************************************************************/

drop table ProdSupport.dbo.tbl_Delete_All_HCC_RAPS_PartC_AetnaTest

select distinct 
	PaymentYear, 
	HICN, 
	HCC, 
	Hierarchy = CAST(NULL as varchar(1)), 
	HeirHCC = CAST(NULL as varchar(10)),
	PlanID,
	RAFactorType
into 
	ProdSupport.dbo.tbl_Delete_All_HCC_RAPS_PartC_AetnaTest
from 
	ProdSupport.dbo.tbl_Delete_All_Diags_RAPS_PartC_AetnaTest 
where 
	HCC is not null 
	and Deleted = 'D'
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
	ProdSupport.dbo.tbl_Delete_All_Diags_RAPS_PartC_AetnaTest 
where 
	HCC is not null 
	and Deleted is null

select * from ProdSupport.dbo.tbl_Delete_All_Diags_RAPS_PartC_AetnaTest
select * from ProdSupport.dbo.tbl_Delete_All_HCC_RAPS_PartC_AetnaTest

/**********************************************************************************
Apply Hierarchy
**********************************************************************************/

UPDATE A
SET Hierarchy = 'L'
FROM ProdSupport.dbo.tbl_Delete_All_HCC_RAPS_PartC_AetnaTest A
WHERE EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_Delete_All_Diags_RAPS_PartC_AetnaTest B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND B.HCC = C.HCC_KEEP
               AND A.HCC = C.HCC_DROP
               AND A.PaymentYear = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
        where b.Accepted = 1 and b.Deleted is NULL
	)

UPDATE A
SET Hierarchy = 'L'
FROM ProdSupport.dbo.tbl_Delete_All_HCC_RAPS_PartC_AetnaTest A
WHERE EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_Delete_All_HCC_RAPS_PartC_AetnaTest B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND B.HCC = C.HCC_KEEP
               AND A.HCC = C.HCC_DROP
               AND A.PaymentYear = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
	)

UPDATE A
SET Hierarchy = 'H'
FROM ProdSupport.dbo.tbl_Delete_All_HCC_RAPS_PartC_AetnaTest A
WHERE Hierarchy is null
AND	EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_Delete_All_Diags_RAPS_PartC_AetnaTest B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND A.HCC = C.HCC_KEEP
               AND B.HCC = C.HCC_DROP
               AND A.PaymentYear = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
        where b.Accepted = 1 and b.Deleted is NULL
	)
	
drop table if exists #HierHCC

select distinct a.PaymentYear, a.HICN, a.HCC, b.HCC HierHCC, RANK() over (partition by a.hicn, a.hcc order by b.hcc) rnk
into #HierHCC
from 
      ProdSupport.dbo.tbl_Delete_All_HCC_RAPS_PartC_AetnaTest a
      join ProdSupport.dbo.tbl_Delete_All_Diags_RAPS_PartC_AetnaTest b
      on a.PaymentYear = b.PaymentYear
      and a.HICN = b.HICN
      join HRPReporting.dbo.lk_Risk_Models_Hierarchy C
      on a.HCC = c.HCC_KEEP
      and b.HCC = c.HCC_DROP
      and b.PaymentYear  = c.Payment_Year
      and b.RAFactorType = c.RA_FACTOR_TYPE
where 
      a.Hierarchy = 'H'

update a
set a.HeirHCC = b.HierHCC
from ProdSupport.dbo.tbl_Delete_All_HCC_RAPS_PartC_AetnaTest a
join #HierHCC b
on a.HICN = b.HICN
and a.HCC = b.HCC
and a.PaymentYear = b.PaymentYear
and b.rnk = 1

--if Lower HCC is deleted, there is still Higher HCC active ... in that case ... no delete impact
--if Higher HCC is deleted, there is still lower HCC active ... in that case ... partial delete impact  ... and need to report lower HCC that is active 


/**********************************************************************************
Final list of New HCC after filtering out lower Hierarchy HCC
Final New HCC table - ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest
**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_Delete_New_HCC_RAPS_PartC_AetnaTest

select distinct 
	a.PaymentYear, 
	a.HICN, 
	a.HCC, 
	a.HeirHCC,
	RAFactorType
into ProdSupport.dbo.tbl_Delete_New_HCC_RAPS_PartC_AetnaTest
from
	ProdSupport.dbo.tbl_Delete_All_HCC_RAPS_PartC_AetnaTest a
Where
	a.Hierarchy is NULL or a.Hierarchy = 'H'

select * from ProdSupport.dbo.tbl_Delete_New_HCC_RAPS_PartC_AetnaTest