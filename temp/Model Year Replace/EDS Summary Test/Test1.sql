select 'Before', * from ProdSupport.dbo.tbl_Summary_RskAdj_EDSBefore	unlock
where HICN = '8WV2FQ0VY24 ' and PaymentYear = 2021
union all	
select 'After', * from ProdSupport.dbo.tbl_Summary_RskAdj_EDSAfter unlock
where HICN = '8WV2FQ0VY24' and PaymentYear = 2021

select 'After', * from ProdSupport.dbo.tbl_Summary_RskAdj_EDS_After unlock
where PaymentYear = 2021
and factor_category  = 'APCC'

select * from ProdSupport.dbo.tbl_Summary_RskAdj_EDSAfter unlock
where HICN = '8WV2FQ0VY24' and PaymentYear = 2021
union all 
select * from ProdSupport.dbo.tbl_Summary_RskAdj_EDSBefore unlock
where HICN = '8WV2FQ0VY24' and PaymentYear = 2021

select loaddatetime, count(1) from ProdSupport.dbo.tbl_Summary_RskAdj_EDSBefore unlock
where PaymentYear = 2021
group by loaddatetime

select loaddatetime, count(1) from ProdSupport.dbo.tbl_Summary_RskAdj_EDSAfter unlock
where PaymentYear = 2021
group by loaddatetime

select loaddatetime, count(1) from Aetna_Report.rev.tbl_Summary_RskAdj_EDS unlock
where PaymentYear = 2021
group by loaddatetime

select loaddatetime, count(1) from Aetna_Report.rev.tbl_Summary_RskAdj_EDS_Preliminary unlock
where PaymentYear = 2021
group by loaddatetime

select HICN, HCC_Number, Factor, RAFT from ProdSupport.dbo.tbl_Summary_RskAdj_EDSAfter unlock
where  PaymentYear = 2021
and Factor_category = 'EDS'
except
select HICN, HCC_Number, Factor, RAFT from ProdSupport.dbo.tbl_Summary_RskAdj_EDSBefore unlock
where PaymentYear = 2021
and Factor_category = 'EDS'
except
select HICN, HCC_Number, Factor, RAFT from ProdSupport.dbo.tbl_Summary_RskAdj_EDSAfter unlock
where  PaymentYear = 2021
and Factor_category = 'EDS'

select 
	PlanID, HICN, PaymentYear, PaymStart, Factor_category, Factor_Desc, Factor, RAFT, HCC_Number, Min_ProcessBy, Min_ThruDate, Min_Processby_DiagCD, Min_ThruDate_DiagCD, Min_ProcessBy_PCN, Min_ThruDate_PCN, processed_priority_thru_date, thru_priority_processed_by, RAFT_ORIG, Processed_Priority_FileID, Processed_Priority_RAPS_Source_ID, Processed_Priority_Provider_ID, Processed_Priority_RAC, Thru_Priority_FileID, Thru_Priority_RAPS_Source_ID, Thru_Priority_Provider_ID, Thru_Priority_RAC, IMFFlag, Factor_Desc_ORIG, Factor_Desc_EstRecev, Aged, LastAssignedHICN
from ProdSupport.dbo.tbl_Summary_RskAdj_EDSAfter unlock
where PaymentYear = 2021
except
select 
	PlanID, HICN, PaymentYear, PaymStart, Factor_category, Factor_Desc, Factor, RAFT, HCC_Number, Min_ProcessBy, Min_ThruDate, Min_Processby_DiagCD, Min_ThruDate_DiagCD, Min_ProcessBy_PCN, Min_ThruDate_PCN, processed_priority_thru_date, thru_priority_processed_by, RAFT_ORIG, Processed_Priority_FileID, Processed_Priority_RAPS_Source_ID, Processed_Priority_Provider_ID, Processed_Priority_RAC, Thru_Priority_FileID, Thru_Priority_RAPS_Source_ID, Thru_Priority_Provider_ID, Thru_Priority_RAC, IMFFlag, Factor_Desc_ORIG, Factor_Desc_EstRecev, Aged, LastAssignedHICN
from ProdSupport.dbo.tbl_Summary_RskAdj_EDSBefore unlock
where PaymentYear = 2021



drop table #temp
select * 
into #temp
from
(
(
select 
	'After' label,  PlanID, HICN, PaymentYear, PaymStart, Factor_category, Factor_Desc, Factor, RAFT, HCC_Number, Min_ProcessBy, Min_ThruDate, Min_Processby_DiagCD, Min_ThruDate_DiagCD, Min_ProcessBy_PCN, Min_ThruDate_PCN, processed_priority_thru_date, thru_priority_processed_by, RAFT_ORIG, Processed_Priority_FileID, Processed_Priority_RAPS_Source_ID, Processed_Priority_Provider_ID, Processed_Priority_RAC, Thru_Priority_FileID, Thru_Priority_RAPS_Source_ID, Thru_Priority_Provider_ID, Thru_Priority_RAC, IMFFlag, Factor_Desc_ORIG, Factor_Desc_EstRecev, Aged, LastAssignedHICN
from ProdSupport.dbo.tbl_Summary_RskAdj_EDSAfter unlock
where PaymentYear = 2021
and hicn = '8WV2FQ0VY24' 
except
select 
	'After' label,  PlanID, HICN, PaymentYear, PaymStart, Factor_category, Factor_Desc, Factor, RAFT, HCC_Number, Min_ProcessBy, Min_ThruDate, Min_Processby_DiagCD, Min_ThruDate_DiagCD, Min_ProcessBy_PCN, Min_ThruDate_PCN, processed_priority_thru_date, thru_priority_processed_by, RAFT_ORIG, Processed_Priority_FileID, Processed_Priority_RAPS_Source_ID, Processed_Priority_Provider_ID, Processed_Priority_RAC, Thru_Priority_FileID, Thru_Priority_RAPS_Source_ID, Thru_Priority_Provider_ID, Thru_Priority_RAC, IMFFlag, Factor_Desc_ORIG, Factor_Desc_EstRecev, Aged, LastAssignedHICN
from ProdSupport.dbo.tbl_Summary_RskAdj_EDSBefore unlock
where PaymentYear = 2021
and hicn = '8WV2FQ0VY24'
)
union all
(
select 
	'Before' label,  PlanID, HICN, PaymentYear, PaymStart, Factor_category, Factor_Desc, Factor, RAFT, HCC_Number, Min_ProcessBy, Min_ThruDate, Min_Processby_DiagCD, Min_ThruDate_DiagCD, Min_ProcessBy_PCN, Min_ThruDate_PCN, processed_priority_thru_date, thru_priority_processed_by, RAFT_ORIG, Processed_Priority_FileID, Processed_Priority_RAPS_Source_ID, Processed_Priority_Provider_ID, Processed_Priority_RAC, Thru_Priority_FileID, Thru_Priority_RAPS_Source_ID, Thru_Priority_Provider_ID, Thru_Priority_RAC, IMFFlag, Factor_Desc_ORIG, Factor_Desc_EstRecev, Aged, LastAssignedHICN
from ProdSupport.dbo.tbl_Summary_RskAdj_EDSBefore unlock
where PaymentYear = 2021
and hicn = '8WV2FQ0VY24'
except
select 
	'Before' label,  PlanID, HICN, PaymentYear, PaymStart, Factor_category, Factor_Desc, Factor, RAFT, HCC_Number, Min_ProcessBy, Min_ThruDate, Min_Processby_DiagCD, Min_ThruDate_DiagCD, Min_ProcessBy_PCN, Min_ThruDate_PCN, processed_priority_thru_date, thru_priority_processed_by, RAFT_ORIG, Processed_Priority_FileID, Processed_Priority_RAPS_Source_ID, Processed_Priority_Provider_ID, Processed_Priority_RAC, Thru_Priority_FileID, Thru_Priority_RAPS_Source_ID, Thru_Priority_Provider_ID, Thru_Priority_RAC, IMFFlag, Factor_Desc_ORIG, Factor_Desc_EstRecev, Aged, LastAssignedHICN
from ProdSupport.dbo.tbl_Summary_RskAdj_EDSAfter unlock
where PaymentYear = 2021
and hicn = '8WV2FQ0VY24' 
)
) a


select * from #temp
order by label

select * from Aetna_Report.rev.tbl_Summary_RskAdj_EDS_Preliminary unlock
where PaymentYear = 2021
and HICN = '1AP9Q68RJ17'


select * from HRPReporting.[dbo].[lkRiskModelsFactors]
where DemoRiskType = 'APCC'



select top 10 * from ProdSupport.dbo.tbl_Summary_RskAdj_EDS_MOR_CombinedBefore 
select top 10 * from ProdSupport.dbo.tbl_Summary_RskAdj_EDS_MOR_CombinedAfter 

select HICN, PaymStart, Factor_desc, Factor, RAFT from ProdSupport.dbo.tbl_Summary_RskAdj_EDS_MOR_CombinedBefore 
except
select HICN, PaymStart, Factor_desc, Factor, RAFT from ProdSupport.dbo.tbl_Summary_RskAdj_EDS_MOR_CombinedAfter 
except
select HICN, PaymStart, Factor_desc, Factor, RAFT from ProdSupport.dbo.tbl_Summary_RskAdj_EDS_MOR_CombinedBefore 

