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
	and b.Factor_Type in ('D1','D2','D3')

select * from #Diag_HCC_Lookup

/**********************************************************************************

creating tbl_Delete_EDS_DiagHCC_rollup_Aetna is ignored for Part D as its already been done in Part C.

**********************************************************************************/

/**********************************************************************************
Create a list of all diags with HCC mapping applied
Apply eligibility using MMR
**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartD_Aetna

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
	m.PartDRAFTMMR RAFactorType,
	m.PlanID
into ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartD_Aetna
from ProdSupport.dbo.tbl_Delete_EDS_DiagHCC_rollup_Aetna a
	inner join ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002a_MMR m
	on a.FinalHICN = m.hicn
	and YEAR(ThroughDateofService) + 1 = m.Paymentyear
	left join #Diag_HCC_Lookup lk
	on a.DiagnosisCode = lk.ICD10CD
    AND lk.Payment_Year = 2020
	and m.PartDRAFTProjected = lk.Factor_Type
where RiskAdjustable = 1
and m.RunID = 2

select * from ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartD_Aetna 

/**********************************************************************************
Find the list of HCC triggered by Deleted = D which do not exist elsewhere in the population
**********************************************************************************/

drop table ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartD_Aetna

select distinct 
	PaymentYear, 
	HICN, 
	HCC, 
	Hierarchy = CAST(NULL as varchar(1)), 
	HeirHCC = CAST(NULL as varchar(10)),
	PlanID,
	RAFactorType
into 
	ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartD_Aetna
from 
	ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartD_Aetna 
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
	ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartD_Aetna 
where 
	HCC is not null 
	and AddOrDeleteFlag <> 'D'

select * from ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartD_Aetna
select * from ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartD_Aetna

/**********************************************************************************
Apply Hierarchy
**********************************************************************************/

drop table if exists #lk_Risk_Models_Hierarchy

select 
	Part_C_D_Flag, 
	RA_FACTOR_TYPE, 
	Payment_Year, 
	replace(HCC_KEEP,' ','') HCC_KEEP, 
	replace(HCC_DROP,' ','') HCC_DROP, 
	HCC_KEEP_NUMBER, 
	HCC_DROP_NUMBER
into #lk_Risk_Models_Hierarchy
from HRPReporting.dbo.lk_Risk_Models_Hierarchy
where Payment_Year = 2020
and RA_FACTOR_TYPE in ('D1','D2','D3')

UPDATE A
SET Hierarchy = 'L'
FROM ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartD_Aetna A
WHERE EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartD_Aetna B
		JOIN #lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND B.HCC = C.HCC_KEEP
               AND A.HCC = C.HCC_DROP
               AND A.PaymentYear = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
        where b.RiskAdjustable = 1 and b.AddOrDeleteFlag is NULL
	)

UPDATE A
SET Hierarchy = 'L'
FROM ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartD_Aetna A
WHERE EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartD_Aetna B
		JOIN #lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND B.HCC = C.HCC_KEEP
               AND A.HCC = C.HCC_DROP
               AND A.PaymentYear = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
	)

UPDATE A
SET Hierarchy = 'H'
FROM ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartD_Aetna A
WHERE Hierarchy is null
AND	EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartD_Aetna B
		JOIN #lk_Risk_Models_Hierarchy C
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
      ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartD_Aetna a
      join ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartD_Aetna b
      on a.PaymentYear = b.PaymentYear
      and a.HICN = b.HICN
      join #lk_Risk_Models_Hierarchy C
      on a.HCC = c.HCC_KEEP
      and b.HCC = c.HCC_DROP
      and b.PaymentYear  = c.Payment_Year
      and b.RAFactorType = c.RA_FACTOR_TYPE
where 
      a.Hierarchy = 'H'

update a
set a.HeirHCC = b.HierHCC
from ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartD_Aetna a
join #HierHCC b
on a.HICN = b.HICN
and a.HCC = b.HCC
and a.PaymentYear = b.PaymentYear
and b.rnk = 1


/**********************************************************************************
Final list of New HCC after filtering out lower Hierarchy HCC
Final New HCC table - ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartD_Aetna
**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_Delete_New_HCC_EDS_PartD_Aetna

select distinct
	a.PaymentYear, 
	a.HICN, 
	a.HCC, 
	a.HeirHCC,
	RAFactorType
into ProdSupport.dbo.tbl_Delete_New_HCC_EDS_PartD_Aetna
from
	ProdSupport.dbo.tbl_Delete_All_HCC_EDS_PartD_Aetna a
Where
	a.Hierarchy is NULL or a.Hierarchy = 'H'

select * from ProdSupport.dbo.tbl_Delete_New_HCC_EDS_PartD_Aetna