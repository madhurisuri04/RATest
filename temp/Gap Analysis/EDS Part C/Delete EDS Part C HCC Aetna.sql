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

drop table if exists ProdSupport.dbo.tbl_GAP_Diags_Delete 

select 
	left(DOSEnd, 4) as DOS_year,
	MemberNumber as MBI,
	FinalMemberNumber as HICN,
	DiagnosisCode,
	DOSStart,
	DOSEnd,
	ProviderType
into ProdSupport.dbo.tbl_GAP_Diags_Delete 
from ReportingETL.[HRP\hasan.farooqui].hst_AETGapCheck_000a_Source
where RunID = 3 and Status = 'D'


/**********************************************************************************
Diag HCC Mapping for 2020 PY
Use 2020 Model Year for EDS
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
Create subset of EDS_Diag_HCC_Rollup table containing only members to be deleted
Take only Accepted = 1 so that there are no deletes captured
**********************************************************************************/
/*
select top 100 * from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002e_EDS_Source

select RiskAdjustable, AddorDeleteFlag, count(1) from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002e_EDS_Source
group by RiskAdjustable, AddorDeleteFlag
*/

drop table if exists ProdSupport.dbo.tbl_Delete_EDS_DiagHCC_rollup_Aetna 

select * 
into 
	ProdSupport.dbo.tbl_Delete_EDS_DiagHCC_rollup_Aetna
from 
	ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002e_EDS_Source r
where YEAR(ThroughDateofService) = 2019
and RiskAdjustable = 1
and exists (select 1 from ProdSupport.dbo.tbl_GAP_Diags_Delete d where r.FinalHICN = d.HICN)
and RunID = 2


/**********************************************************************************
Add supplemental data from RAPS for Provider Type 01 and 02
**********************************************************************************/

--select top 10 * from ProdSupport.dbo.tbl_Delete_EDS_DiagHCC_rollup_Aetna
--select top 10 * from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002d_RAPS_Source

insert into ProdSupport.dbo.tbl_Delete_EDS_DiagHCC_rollup_Aetna
(
	RunID ,
	LOB ,
	EncounterICN,
	FinalHICN ,
	EncounterSubmissionDate ,
	FromDateofService ,
	ThroughDateofService ,
	DiagnosisCode ,
	AddOrDeleteFlag ,
	RiskAdjustable ,
	ProviderType ,
	PopulatedDate 
)
Select
	RunID = RunID,
	LOB = LOB,
	EncounterICN = 999999,
	FinalHICN = FinalHICN,
	EncounterSubmissionDate = ProcessedBy,
	FromDateofService = FromDate,
	ThroughDateofService = ThruDate,
	DiagnosisCode = DiagnosisCode,
	AddOrDeleteFlag = 'A',
	RiskAdjustable = 1,
	ProviderType = ProviderType,
	PopulatedDate = PopulatedDate
from
	ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002d_RAPS_Source r
where 
	YEAR(Thrudate) = 2019
	and Accepted = 1
	and Deleted is null
	and exists (select 1 from ProdSupport.dbo.tbl_GAP_Diags_Delete d where r.FinalHICN = d.HICN)
	and ProviderType in ('01','02')
	and RunID = 2


/**********************************************************************************
For all matching cluster in the delete list, update Deleted = 'D'
**********************************************************************************/

-- Update for EDS MAO004 records
update b
set 
	AddOrDeleteFlag = 'D'
from 
ProdSupport.dbo.tbl_Delete_EDS_DiagHCC_rollup_Aetna (nolock) b
join ProdSupport.dbo.tbl_GAP_Diags_Delete a
on	a.HICN = b.FinalHICN
and a.DOSStart = b.FromDateofService
and a.DOSEnd = b.ThroughDateofService
and a.DiagnosisCode = b.DiagnosisCode
and b.EncounterTypeSwitch >= 4
and b.EncounterICN <> 999999

-- Update for RAPS supplemental records
update b
set 
	AddOrDeleteFlag = 'D'
from 
ProdSupport.dbo.tbl_Delete_EDS_DiagHCC_rollup_Aetna (nolock) b
join ProdSupport.dbo.tbl_GAP_Diags_Delete a
on	a.HICN = b.FinalHICN
and a.DOSStart = b.FromDateofService
and a.DOSEnd = b.ThroughDateofService
and a.DiagnosisCode = b.DiagnosisCode
and a.ProviderType = b.ProviderType
and b.EncounterICN = 999999

/**********************************************************************************
Create a list of all diags with HCC mapping applied
Apply eligibility using MMR
**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartC_Aetna

select distinct 
	EncounterSource = 'EDS', 
	PaymentYear = YEAR(ThroughDateofService) + 1, 
	a.FinalHICN HICN, 
	FromDateofService FromDate, 
	ThroughDateofService ThruDate, 
	ProviderType, 
	DiagnosisCode, 
	HCC = lk.HCC_Label,
	RiskAdjustable,
	AddOrDeleteFlag,
	m.PartCRAFTMMR RAFactorType,
	m.PlanID
into ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartC_Aetna
from ProdSupport.dbo.tbl_Delete_EDS_DiagHCC_rollup_Aetna a
	inner join ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002a_MMR m
	on a.FinalHICN = m.hicn
	and YEAR(ThroughDateofService) + 1 = m.Paymentyear
	left join #Diag_HCC_Lookup lk
	on a.DiagnosisCode = lk.ICD10CD
    AND lk.Payment_Year = 2020
	and m.PartCRAFTProjected = lk.Factor_Type
where RiskAdjustable = 1
and m.RunID = 2

select * from ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartC_Aetna 

/**********************************************************************************
Find the list of HCC triggered by Deleted = D which do not exist elsewhere in the population
**********************************************************************************/

drop table ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartC_Aetna

select distinct 
	PaymentYear, 
	HICN, 
	HCC, 
	Hierarchy = CAST(NULL as varchar(1)), 
	HeirHCC = CAST(NULL as varchar(10)),
	PlanID,
	RAFactorType
into 
	ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartC_Aetna
from 
	ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartC_Aetna 
where 
	HCC is not null 
	and AddOrDeleteFlag = 'D'
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
	ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartC_Aetna 
where 
	HCC is not null 
	and AddOrDeleteFlag <> 'D'

select * from ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartC_Aetna
select * from ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartC_Aetna

/**********************************************************************************
Apply Hierarchy
**********************************************************************************/

UPDATE A
SET Hierarchy = 'L'
FROM ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartC_Aetna A
WHERE EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartC_Aetna B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND B.HCC = C.HCC_KEEP
               AND A.HCC = C.HCC_DROP
               AND A.PaymentYear = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
        where b.RiskAdjustable = 1 and b.AddOrDeleteFlag is NULL
	)

UPDATE A
SET Hierarchy = 'L'
FROM ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartC_Aetna A
WHERE EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartC_Aetna B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND B.HCC = C.HCC_KEEP
               AND A.HCC = C.HCC_DROP
               AND A.PaymentYear = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
	)

UPDATE A
SET Hierarchy = 'H'
FROM ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartC_Aetna A
WHERE Hierarchy is null
AND	EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartC_Aetna B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND A.HCC = C.HCC_KEEP
               AND B.HCC = C.HCC_DROP
               AND A.PaymentYear = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
        where b.RiskAdjustable = 1 and b.AddOrDeleteFlag is NULL
	)
	
drop table if exists #HierHCC

select distinct a.PaymentYear, a.HICN, a.HCC, b.HCC HierHCC, RANK() over (partition by a.hicn, a.hcc order by b.hcc) rnk
into #HierHCC
from 
      ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartC_Aetna a
      join ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartC_Aetna b
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
from ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartC_Aetna a
join #HierHCC b
on a.HICN = b.HICN
and a.HCC = b.HCC
and a.PaymentYear = b.PaymentYear
and b.rnk = 1


/**********************************************************************************
Final list of New HCC after filtering out lower Hierarchy HCC
Final New HCC table - ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_Aetna
**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_Delete_New_HCC_EDS_PartC_Aetna

select distinct
	a.PaymentYear, 
	a.HICN, 
	a.HCC, 
	a.HeirHCC,
	RAFactorType
into ProdSupport.dbo.tbl_Delete_New_HCC_EDS_PartC_Aetna
from
	ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartC_Aetna a
Where
	a.Hierarchy is NULL or a.Hierarchy = 'H'

select * from ProdSupport.dbo.tbl_Delete_New_HCC_EDS_PartC_Aetna