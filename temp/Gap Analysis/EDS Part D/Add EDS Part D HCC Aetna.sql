/**********************************************************************************
Get Source Gap data and populate it into temp prodsupport table
**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_GAP_Diags_Add 

select 
	left(DOSEnd, 4) as DOS_year,
	MemberNumber as MBI,
	FinalMemberNumber as HICN,
	DiagnosisCode,
	DOSStart,
	DOSEnd,
	ProviderType
into ProdSupport.dbo.tbl_GAP_Diags_Add 
from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_000a_Source
where RunID = 3 and Status = 'A'


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
Create ALL Diag table for population members and check eligibility with MMR

Use already created EDS Source table  - ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002e_EDS_Source
Use already created MMR Source table - ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002a_MMR

**********************************************************************************/
drop table if exists ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartD_Aetna

/**********************************************************************************
Insert all diagnoses from EDS Source table 
**********************************************************************************/


-- truncate table ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartD_Aetna

-- insert into ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartD_Aetna
select distinct 
	EncounterSource = 'EDS', 
	PaymentYear = YEAR(ThroughDateofService) + 1, 
	a.FinalHICN HICN, 
	FromDate = FromDateofService, 
	ThruDate = ThroughDateofService, 
	DiagnosisCode, 
	ProviderType,
	HCC = lk.HCC_Label,
	'N' IsAdded,
	m.PartDRAFTProjected RAFactorType,
	m.PlanID
into ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartD_Aetna
from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002e_EDS_Source a
	inner join ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002a_MMR m
	on a.FinalHICN = m.hicn
	left join #Diag_HCC_Lookup lk
	on a.DiagnosisCode = lk.ICD10CD
    AND lk.Payment_Year = 2020
	and m.PartDRAFTProjected = lk.Factor_Type
where YEAR(ThroughDateofService) = 2019 
	and RiskAdjustable = 1 
	and AddOrDeleteFlag  = 'A'
	and a.RunID = 2
	and m.RunID = 2

/**********************************************************************************
insert all Add diagnoses from Extract file
**********************************************************************************/

insert into ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartD_Aetna
select distinct 
	'EDS', 
	YEAR(DOSEnd) + 1, 	
	a.HICN, 
	DOSStart, 
	DOSEnd, 
	DiagnosisCode,
	ProviderType,
	HCC = lk.HCC_Label,
	'Y' as IsAdded,
	m.PartDRAFTProjected RAFactorType,
	m.PlanID
from 
	ProdSupport.dbo.tbl_GAP_Diags_Add a 
	inner join ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002a_MMR m
	on a.HICN = m.HICN
	left join #Diag_HCC_Lookup lk
	on a.DiagnosisCode = lk.ICD10CD
    AND lk.Payment_Year = 2020
	and m.PartDRAFTProjected = lk.Factor_Type
where a.DOS_year = 2019 
	and m.RunID = 2

/**********************************************************************************
Get all New HCC that do not exist in current diag list
**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartD_Aetna

--truncate table ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartD_Aetna

--insert into ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartD_Aetna
select distinct 
	PaymentYear, 
	HICN, 
	HCC, 
	Hierarchy = CAST(NULL as varchar(1)), 
	HeirHCC = CAST(NULL as varchar(10)), 
	PlanID,
	RAFactorType
into ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartD_Aetna
from 
	ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartD_Aetna
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
	ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartD_Aetna
where 
	HCC is not null 
	and IsAdded = 'N'


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
FROM ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartD_Aetna A
WHERE 
	EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartD_Aetna B
		JOIN #lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND B.HCC = C.HCC_KEEP
               AND A.HCC = C.HCC_DROP
               AND C.Payment_Year = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
        where IsAdded = 'N'
	)

UPDATE A
SET Hierarchy = 'L'
FROM ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartD_Aetna A
WHERE 
	EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartD_Aetna B
		JOIN #lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND B.HCC = C.HCC_KEEP
               AND A.HCC = C.HCC_DROP
               AND C.Payment_Year = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
	)

UPDATE A
SET Hierarchy = 'H'
FROM ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartD_Aetna A
WHERE Hierarchy is null
AND	EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartD_Aetna B
		JOIN #lk_Risk_Models_Hierarchy C
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
      ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartD_Aetna a
      join ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartD_Aetna b
      on a.PaymentYear = b.PaymentYear
      and a.HICN = b.HICN
      join #lk_Risk_Models_Hierarchy C
      on a.HCC = c.HCC_KEEP
      and b.HCC = c.HCC_DROP
      and b.PaymentYear = c.Payment_Year
      and b.RAFactorType = c.RA_FACTOR_TYPE 
where 
      a.Hierarchy = 'H'

update a
set 
	a.HeirHCC = b.HierHCC
from ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartD_Aetna a
join #HierHCC b
on a.HICN = b.HICN
and a.HCC = b.HCC
and a.PaymentYear = b.PaymentYear
and b.rnk = 1

/**********************************************************************************
Final list of New HCC after filtering out lower Hierarchy HCC
Final New HCC table - ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartD_Aetna
**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartD_Aetna

select distinct
	a.PaymentYear, 
	a.HICN, 
	a.HCC, 
	a.HeirHCC
into ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartD_Aetna
from
	ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartD_Aetna a
Where
	a.Hierarchy is NULL or a.Hierarchy = 'H'

/**********************************************************************************
 Final list of New HCC 
 The records with Non NULL HierHCC means they are partially impacted
**********************************************************************************/

select * from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartD_Aetna


