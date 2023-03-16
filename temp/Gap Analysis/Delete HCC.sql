/*
SELECT *
FROM [REG_ClientLevel].[dbo].[tbl_RAPSSubmissionBatchExportedFile]
where SubmittedFileName  in (
'pending'
)

drop table ProdSupport.dbo.tbl_Reg_RAPS_New_DELETE_2020

select * 
into ProdSupport.dbo.tbl_Reg_RAPS_New_DELETE_2020
from [REG_ClientLevel].[dbo].[tbl_RAPSSubmissionBatchDetail]
where RAPSSubmissionBatchExportedFileID in (647)

select * from ProdSupport.dbo.tbl_Reg_RAPS_New_DELETE_2020

select year(Thru_date), count(1) from ProdSupport.dbo.tbl_Reg_RAPS_New_DELETE_2020
group by year(Thru_date)

*/

--Total by year
select left(from_date, 4) as DOS_year, count(*) as N_Year from ProdSupport.dbo.tbl_Reg_RAPS_New_DELETE_2020 --name of table just created
group by left(from_date, 4) 
order by left(from_date, 4) 
--DOS_year	N_Year
--2019	28409
--2020	12920


drop table ProdSupport.dbo.tbl_REG_RAPS_DiagHCC_rollup_Vanilla_0723 --- change this table name to date at the end and change throughout the full query
select * 
into 
	ProdSupport.dbo.tbl_REG_RAPS_DiagHCC_rollup_Vanilla_0723
from 
	REG_Report.dbo.RAPS_DiagHCC_rollup r
where YEAR(Thrudate) =2019
	and exists (select 1 from ProdSupport.dbo.tbl_Reg_RAPS_New_DELETE_2020 d where r.hicn = d.HICN)

---select * from ProdSupport.dbo.tbl_Reg_RAPS_New_DELETE_2020

	update b
	set 
		Void_Indicator = NULL,
		Voided_By_RAPSID = '9999990',
		Deleted = 'D'
	from 
	ProdSupport.dbo.tbl_REG_RAPS_DiagHCC_rollup_Vanilla_0723 (nolock) b
	join ProdSupport.dbo.tbl_Reg_RAPS_New_DELETE_2020 a
	on	a.HICN = b.HICN
	and a.from_date = b.FromDate
	and a.thru_date = b.ThruDate
	and a.Diag = b.DiagnosisCode
	and a.Provd_Type = b.providerType

---select * from ProdSupport.dbo.tbl_REG_RAPS_DiagHCC_rollup_Vanilla_0723 where Deleted = 'D' and Accepted = 1

/* Test Start */

select * into #temp
from
(
select hicn, provd_type, from_date, thru_date, diag from ProdSupport.dbo.tbl_Reg_RAPS_New_DELETE_2020
except
select hicn, ProviderType, FromDate, ThruDate, DiagnosisCode from REG_Report.dbo.RAPS_DiagHCC_rollup r
--where YEAR(Thrudate) >=2019
) a

select * from #temp

select * from
(
select hicn, provd_type, from_date, thru_date, diag, 'In File' location from ProdSupport.dbo.tbl_Reg_RAPS_New_DELETE_2020 d
where exists (select 1 from #temp t where d.hicn = t.hicn and d.from_date = t.from_date and d.thru_date = t.thru_date and d.diag = t.diag)
--order by hicn, diag, from_date, thru_date
union all 
select distinct hicn, ProviderType, fromdate, thrudate, DiagnosisCode, 'In RAPS' location from REG_Report.dbo.RAPS_DiagHCC_rollup d
where exists (select 1 from #temp t where d.hicn = t.hicn and d.fromdate = t.from_date and d.ThruDate = t.thru_date and d.DiagnosisCode = t.diag)
) a
order by hicn, diag, from_date, thru_date

/* Test End */


DROP TABLE #Diag_HCC_Lookup

Select distinct 
	b.ICDClassification,
	b.ICDCode,
	b.HCCLabel,
	D.PaymentYear,
	b.FactorType
--	ef.StartDate,
--	ef.EndDate
	,Case when D.PaymentYear in (2020) Then 2018 Else D.ModelYear END as ModelYear
	,Factor
	,Aged
	,SubmissionModel
into 
	#Diag_HCC_Lookup 
from
	HRPReporting.dbo.[Vw_LkRiskModelsDiagHCC] B  (nolock)  
--	INNER JOIN 
--			HRPREPORTING.dbo.ICDEffectiveDates ef   (nolock)
--			ON B.ICDClassification = ef.ICDClassification
--			AND B.FactorType = 'CN'
	INNER JOIN 
			HRPReporting.dbo.lk_Risk_Models E    (nolock)
			ON B.HCCLabel = E.Factor_Description  
			AND B.PaymentYear = E.Payment_Year
			AND Part_C_D_Flag = 'C'  
			AND B.FactorType = E.Factor_Type 
			and E.Aged = 1
	INNER JOIN 
			HRPReporting.dbo.lk_Risk_Score_Factors_PartC D  (nolock)  
			ON SubmissionModel = 'RAPS'
			and d.RAFactorType = b.FactorType 
			AND B.PaymentYear  = Case when D.PaymentYear in (2020) Then 2018 Else D.ModelYear END 
where  
	D.PaymentYear in (2020)
	and B.ICDClassification = 10
	and b.FactorType not in ('E','E1','E2','SE','ED')

select Factor_Type, count(1) from HRPReporting.dbo.lk_Risk_Models where Payment_Year = 2020
group by factor_type
order by Factor_Type

drop table #Temp_SummaryMMR

select * 
	into #Temp_SummaryMMR
from 
	REG_Report.rev.tbl_Summary_RskAdj_MMR (nolock)
where 
	HICN in (select HICN from ProdSupport.dbo.tbl_Reg_RAPS_New_DELETE_2020)
	and PaymentYear in (2020)

drop table #Temp_MMR1
select 
	paymentYear, 
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
	paymentYear, 
	HICN, 
	PartCRaftMMR

drop table #Temp_MMR2
select 
	hicn, 
	max(PaymStart) PaymStart,
	sum(PaymentMonths) PaymentMonths
into #Temp_MMR2
from #Temp_MMR1
group by 
	hicn

update a
set a.rnk = 1
from #Temp_MMR1 a
inner join #Temp_MMR2 b
on a.hicn = b.hicn
and a.paymstart = b.paymstart

drop table  ProdSupport.dbo.tbl_REG_All_Diags

select distinct 
	EncounterSource = 'RAPS', 
	PaymentYear = YEAR(ThruDate) + 1, 
	r.HICN, 
	FromDate, 
	ThruDate, 
	ProviderType, 
	DiagnosisCode, 
	HCC = CAST(NULL as varchar(10)), 
	HCCFactor = CAST(NULL as float), 
	Hierarchy = CAST(NULL as varchar(1)), 
	Deleted,
	Accepted,
	m.PartCRAFTMMR RAFactorType,
	m.PlanID,
	m.PBP,
	m.SCC,
	n.PaymentMonths
into ProdSupport.dbo.tbl_REG_All_Diags
from ProdSupport.dbo.tbl_REG_RAPS_DiagHCC_rollup_Vanilla_0723 r
	inner join #Temp_MMR1 m
	on r.hicn = m.hicn
	and Rnk = 1
	inner join #Temp_MMR2 n
	on r.hicn = n.hicn
where Accepted = 1
and r.HICN in (select HICN from ProdSupport.dbo.tbl_REG_RAPS_DiagHCC_rollup_Vanilla_0723 where Deleted = 'D' and Accepted = 1)

select * from ProdSupport.dbo.tbl_REG_All_Diags 

Update a
set a.HCC = b.HCCLabel, HCCFactor = b.Factor
from ProdSupport.dbo.tbl_REG_All_Diags a
join #Diag_HCC_Lookup b
	ON A.DiagnosisCode = B.ICDCode
    AND a.PaymentYear = b.PaymentYear
	and a.RAFactorType = b.FactorType

drop table ProdSupport.dbo.tbl_REG_All_Diags_wHierApplied

select distinct 
	PaymentYear, 
	HICN, 
	HCC, 
	HCCFactor, 
	Hierarchy = CAST(NULL as varchar(1)), 
	HeirHCC = CAST(NULL as varchar(10)), 
	HeirHCCFactor = CAST(NULL as float)
into 
	ProdSupport.dbo.tbl_REG_All_Diags_wHierApplied
from 
	ProdSupport.dbo.tbl_REG_All_Diags 
where 
	HCC is not null 
	and Deleted = 'D'
Except
select distinct 
	PaymentYear, 
	HICN, 
	HCC, 
	HCCFactor, 
	NULL, NULL, NULL
from 
	ProdSupport.dbo.tbl_REG_All_Diags 
where 
	HCC is not null 
	and Deleted is null

select * from ProdSupport.dbo.tbl_REG_All_Diags
select * from ProdSupport.dbo.tbl_REG_All_Diags_wHierApplied


UPDATE A
SET Hierarchy = 'L'
FROM ProdSupport.dbo.tbl_REG_All_Diags_wHierApplied A
WHERE EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_REG_All_Diags B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND B.HCC = C.HCC_KEEP
               AND A.HCC = C.HCC_DROP
               AND A.PaymentYear = B.PaymentYear
               --AND A.ModelYear = B.ModelYear
               AND C.RA_FACTOR_TYPE = 'CN' 
        where b.Accepted = 1 and b.Deleted is NULL
	)

UPDATE A
SET Hierarchy = 'H'
FROM ProdSupport.dbo.tbl_REG_All_Diags_wHierApplied A
WHERE Hierarchy is null
AND	EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_REG_All_Diags B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND A.HCC = C.HCC_KEEP
               AND B.HCC = C.HCC_DROP
               AND A.PaymentYear = B.PaymentYear
               --AND A.ModelYear = B.ModelYear
               AND C.RA_FACTOR_TYPE = 'CN' 
        where b.Accepted = 1 and b.Deleted is NULL
	)
	
drop table #HierHCC

select distinct a.PaymentYear, a.HICN, a.HCC, b.HCC HierHCC, b.HCCFactor HeirHCCFactor, RANK() over (partition by a.hicn, a.hcc order by b.hcc) rnk
into #HierHCC
from 
      ProdSupport.dbo.tbl_REG_All_Diags_wHierApplied a
      join ProdSupport.dbo.tbl_REG_All_Diags b
      on a.PaymentYear = b.PaymentYear
      and a.HICN = b.HICN
      join HRPReporting.dbo.lk_Risk_Models_Hierarchy C
      on a.HCC = c.HCC_KEEP
      and b.HCC = c.HCC_DROP
      and c.Payment_Year in (2020)
      and c.RA_FACTOR_TYPE = 'CN'
where 
      a.Hierarchy = 'H'

update a
set a.HeirHCC = b.HierHCC, a.HeirHCCFactor = b.HeirHCCFactor
from ProdSupport.dbo.tbl_REG_All_Diags_wHierApplied a
join #HierHCC b--select * from #HierHCC
on a.HICN = b.HICN
and a.HCC = b.HCC
and a.PaymentYear = b.PaymentYear
and b.rnk = 1

drop table #Temp_SummaryMMR
select * 
into #Temp_SummaryMMR
from REG_Report.rev.tbl_Summary_RskAdj_MMR (nolock)
where HICN in (select HICN from ProdSupport.dbo.tbl_REG_All_Diags_wHierApplied)
and PaymentYear = 2020

drop table #Temp_RollForwardMonths
select PaymentYear, HICN, RollforwardMonths = 12-MONTH(LatestPayMStart), PartCRAFTProjected, PlanID, PBP, SCC, BID = CAST(NULL as float)
into #Temp_RollForwardMonths
from (
	select PaymentYear, HICN, PartCRAFTProjected, PlanID, PBP, SCC, LatestPayMStart = PaymStart
	from #Temp_SummaryMMR
	where PaymStart = (select MAX(PaymStart) from #Temp_SummaryMMR)
	group by PaymentYear, HICN, PaymStart, PartCRAFTProjected, PlanID, PBP, SCC
) a


drop table ProdSupport.dbo.tbl_REG_All_Diags_Final

select
	a.PaymentYear, 
	a.HICN, 
	a.HCC, 
	a.HCCFactor, 
	a.HeirHCC, 
	a.HeirHCCFactor, 
	AdjustedFactor = isnull(HCCFactor,0) - ISNULL(HeirHCCFactor,0), 
	b.PlanID, 
	b.PBP, 
	b.SCC, 
	b.PartCRAFTProjected,
	PaymentMonths = count(distinct PaymStart),
	Bid = CAST(NULL as float),
	NormalizationFactor = CAST(NULL as float),
	CodingIntensity = CAST(NULL as float),
	SubmissionSplitWeight = CAST(NULL as float),
	EstimatedImpact = CAST(NULL as float),
	AnnualizedEstimatedImpact = CAST(NULL as float)
into	
	ProdSupport.dbo.tbl_REG_All_Diags_Final
from	
	ProdSupport.dbo.tbl_REG_All_Diags_wHierApplied a
	left join #Temp_SummaryMMR b
	on	a.HICN = b.HICN
	and	a.PaymentYear = b.PaymentYear
Where	
	a.Hierarchy is NULL or a.Hierarchy = 'H'
group by 
	a.PaymentYear, 
	a.HICN, 
	a.HCC, 
	a.HCCFactor, 
	a.HeirHCC, 
	a.HeirHCCFactor, 
	b.PlanID, 
	b.PBP, 
	b.SCC, 
	b.PartCRAFTProjected

select * from ProdSupport.dbo.tbl_REG_All_Diags_Final

--BID look UPDATE 

select PlanIdentifier, Bid_Year, PBP, SCC, MA_BID
into #tbl_Bids_Rollup
from REG_Report.dbo.tbl_Bids_Rollup where Bid_Year in (2020)

select * from #tbl_Bids_Rollup

--Investigate HICN with missing RAFT, Bid, Estimated Value
select RA_Factor_Type, AdjReason, * from  REG_Report.dbo.tbl_MMR_rollup
where HICN = '2N36H67VD54'
order by PaymentDate
--HICN is RAFT = D all of 2020, perform Manual Adjustment

Update	a
Set		a.PaymentMonths = 12
from	ProdSupport.dbo.tbl_REG_All_Diags_Final a
where HICN = '2N36H67VD54'

--DROP extra record for HICN with Issue


Update	a
Set		a.Bid = b.MA_BID
from	ProdSupport.dbo.tbl_REG_All_Diags_Final a
join	#tbl_Bids_Rollup (nolock) b --select * from dbo.tbl_Bids_Rollup
	on	a.PlanID = b.planidentifier 
	and a.PaymentYear = b.Bid_Year
	and a.pbp = b.pbp 
	and a.scc = b.scc 
where	a.PartCRAFTProjected not in ('D', 'ED' )

Update	a
Set		a.Bid = b.MA_BID
from	ProdSupport.dbo.tbl_REG_All_Diags_Final a
join	#tbl_Bids_Rollup (nolock) b --select * from dbo.tbl_Bids_Rollup
	on	a.PlanID = b.planidentifier 
	and a.PaymentYear = b.Bid_Year
	and a.pbp = b.pbp 
	and 'OOA' = b.scc 
where	a.PartCRAFTProjected not in ('D', 'ED' )
	and Bid is null

Update	a
Set		a.Bid = b.rate
from	ProdSupport.dbo.tbl_REG_All_Diags_Final a
JOIN ( SELECT DISTINCT
				Paymo ,
				Code ,
				Rate
	   FROM     HRPReporting.dbo.lk_RATEBOOK_ESRD c
	 ) b 
	ON	a.SCC = b.Code
	AND	a.PaymentYear = b.PayMo	
where	a.PartCRAFTProjected in ('D', 'ED' )

Update	a
Set		a.Bid = b.MA_BID
from	#Temp_RollForwardMonths a
join	#tbl_Bids_Rollup (nolock) b --select * from dbo.tbl_Bids_Rollup
	on	a.PlanID = b.planidentifier 
	and a.PaymentYear = b.Bid_Year
	and a.pbp = b.pbp 
	and a.scc = b.scc 
where	a.PartCRAFTProjected not in ('D', 'ED' )

Update	a
Set		a.Bid = b.MA_BID
from	#Temp_RollForwardMonths a
join	#tbl_Bids_Rollup (nolock) b --select * from dbo.tbl_Bids_Rollup
	on	a.PlanID = b.planidentifier 
	and a.PaymentYear = b.Bid_Year
	and a.pbp = b.pbp 
	and 'OOA' = b.scc 
where	a.PartCRAFTProjected not in ('D', 'ED' )
	and Bid is null

Update	a
Set		a.Bid = b.rate
from	#Temp_RollForwardMonths a
JOIN ( SELECT DISTINCT
				Paymo ,
				Code ,
				Rate
	   FROM     HRPReporting.dbo.lk_RATEBOOK_ESRD c
	 ) b 
	ON	a.SCC = b.Code
	AND	a.PaymentYear = b.PayMo	
where	a.PartCRAFTProjected in ('D', 'ED' )
	
--Aligning Normalization Factors and Coding Intensity Factors for added Impacting HCCs
Update	a
Set		a.NormalizationFactor = b.PartCNormalizationFactor
from	ProdSupport.dbo.tbl_REG_All_Diags_Final a
join	HRPReporting.dbo.lk_Risk_Score_Factors_PartC (nolock) b
	on	a.PaymentYear = b.PaymentYear
	and a.PartCRAFTProjected = b.RAFactorType
where	b.SubmissionModel = 'RAPS'
	and	b.PartCNormalizationFactor <> 0

Update	a
Set		a.NormalizationFactor = b.ESRDDialysisFactor
from	ProdSupport.dbo.tbl_REG_All_Diags_Final a
join	HRPReporting.dbo.lk_Risk_Score_Factors_PartC (nolock) b
	on	a.PaymentYear = b.PaymentYear
	and a.PartCRAFTProjected = b.RAFactorType
where	b.SubmissionModel = 'RAPS'
	and	b.ESRDDialysisFactor <> 0

Update	a
Set		a.NormalizationFactor = b.FunctioningGraftFactor
from	ProdSupport.dbo.tbl_REG_All_Diags_Final a
join	HRPReporting.dbo.lk_Risk_Score_Factors_PartC (nolock) b
	on	a.PaymentYear = b.PaymentYear
	and a.PartCRAFTProjected = b.RAFactorType
where	b.SubmissionModel = 'RAPS'
	and	b.FunctioningGraftFactor <> 0

Update	a
Set		a.CodingIntensity = b.CodingIntensity
from	ProdSupport.dbo.tbl_REG_All_Diags_Final a
join	HRPReporting.dbo.lk_Risk_Score_Factors_PartC (nolock) b
	on	a.PaymentYear = b.PaymentYear
	and a.PartCRAFTProjected = b.RAFactorType
where	b.SubmissionModel = 'RAPS'

--Aligning Submission Model Split weight (RAPS submission / EDS submission split)
Update	a
Set		a.SubmissionSplitWeight = b.SubmissionSplitWeight
from	ProdSupport.dbo.tbl_REG_All_Diags_Final a
join	HRPReporting.dbo.EDSRAPSSubmissionSplit b--select * from HRPReporting.dbo.EDSRAPSSubmissionSplit
	on	a.PaymentYear = b.PaymentYear
	and	b.MYUFLag = 'N'
	and	b.SubmissionModel = 'RAPS'
	
--Deriving Estimated Impact
Update	a
Set		a.EstimatedImpact = round(a.SubmissionSplitWeight * (round(a.PaymentMonths * a.Bid * isnull(round(round(isnull(a.AdjustedFactor, 0) / a.NormalizationFactor, 3) * (1 - a.CodingIntensity), 3), 0), 2)), 2)
from	ProdSupport.dbo.tbl_REG_All_Diags_Final a

Update	a
Set		a.AnnualizedEstimatedImpact = 
			Case when a.PaymentYear = 2021 then
				round(a.SubmissionSplitWeight *	(	(round(a.PaymentMonths		* a.Bid * isnull(round(round(isnull(a.AdjustedFactor, 0) / a.NormalizationFactor, 3) * (1 - a.CodingIntensity), 3), 0), 2)) 
												  +	(round(b.RollForwardMonths	* b.Bid * isnull(round(round(isnull(a.AdjustedFactor, 0) / a.NormalizationFactor, 3) * (1 - a.CodingIntensity), 3), 0), 2))
												)
					  , 2)
				 when a.PaymentYear = 2020 then
				round(a.SubmissionSplitWeight *		(round(	a.PaymentMonths		* a.Bid * isnull(round(round(isnull(a.AdjustedFactor, 0) / a.NormalizationFactor, 3) * (1 - a.CodingIntensity), 3), 0), 2)) 
					  , 2)
			End
from	ProdSupport.dbo.tbl_REG_All_Diags_Final a
left join	#Temp_RollForwardMonths b
	on	a.PaymentYear = b.PaymentYear
	and	a.HICN = b.HICN

/* Dont update this
update ProdSupport.dbo.tbl_REG_All_Diags_Final
set AnnualizedEstimatedImpact = EstimatedImpact
where AnnualizedEstimatedImpact is null
and EstimatedImpact is not null
*/

select PaymentYear, COUNT(distinct HICN+HCC) UNQ_Condition, SUM(AnnualizedEstimatedImpact) , SUM(AnnualizedEstimatedImpact)/COUNT(distinct HICN+HCC)
from ProdSupport.dbo.tbl_REG_All_Diags_Final
where AnnualizedEstimatedImpact > 0
group by PaymentYear

select * from ProdSupport.dbo.tbl_REG_All_Diags_Final

select PaymentYear, b.planid, HICN, HCC, sum(a.AnnualizedEstimatedImpact * -1)
from ProdSupport.dbo.tbl_REG_All_Diags_Final a,
	HRPInternalReports.dbo.RollupPlan b
where 
	a.PlanID = b.PlanIdentifier
	and AnnualizedEstimatedImpact > 0
group by PaymentYear, b.planid, HICN, HCC

select PaymentYear, b.planid, count(HICN+HCC), SUM(AnnualizedEstimatedImpact) 
from ProdSupport.dbo.tbl_REG_All_Diags_Final a,
	HRPInternalReports.dbo.RollupPlan b
where 
	a.PlanID = b.PlanIdentifier
	and AnnualizedEstimatedImpact > 0
group by PaymentYear, b.planid


/**********************************************************************************
STEP 8: Create Report Output
**********************************************************************************/

--Delete Summary Table
--PULL Diagnosis Count from next Query
select 
	PaymentYear as 'Payment Year', 
	'' as 'Diagnosis Count',
	COUNT(distinct HICN+HCC) as 'HCC Count', 
	SUM(AnnualizedEstimatedImpact * -1)  as 'Estimated Annualized Amount'
from ProdSupport.dbo.tbl_REG_All_Diags_Final a
--where AnnualizedEstimatedImpact > 0
group by PaymentYear

--Delete Summary Table - Diagnosis Count
select 
	left(from_date, 4) + 1 as 'Payment Year'
	,count(*) as 'Diagnosis Count' 
from ProdSupport.dbo.tbl_Reg_RAPS_New_DELETE_2020 
group by left(from_date, 4)
order by left(from_date, 4)


--Delete Detail Table
--Members may have split year in different RAFT, group them 
select 
	a.PaymentYear as 'Payment Year'
	,c.PlanID as 'Plan'
	,a.HICN
	,a.HCC
	,sum(a.AnnualizedEstimatedImpact * -1)  as 'Estimated Annualized Amount'
from ProdSupport.dbo.tbl_REG_All_Diags_Final a
join    HRPInternalReports.dbo.RollupPlan (nolock) c
    on    a.PlanID = c.PlanIdentifier
group by a.PaymentYear, c.PlanID, a.HICN, a.HCC
order by a.PaymentYear, c.PlanID, a.HICN, a.HCC
