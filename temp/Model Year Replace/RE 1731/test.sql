USE [PHP_Report]

select * into ProdSupport.[dbo].[tbl_Summary_RskAdj_RAPS]
from rev.[tbl_Summary_RskAdj_RAPS]

select * into ProdSupport.[dbo].[tbl_Summary_RskAdj_RAPS_Preliminary]
from rev.[tbl_Summary_RskAdj_RAPS_Preliminary]


select * from [rev].[tbl_Summary_RskAdj_EDS_Source]

select top 10 * from HRPReporting.[dbo].lk_Risk_Models_DiagHCC_ICD10
where ICD10CD = 'F319'
and payment_Year = 2020
and Factor_Type = 'CN'

select top 10 * from HRPReporting.[dbo].lkRiskModelsDiagHCC
where ICD10CD = 'F319'
and paymentYear = 2020
and RAFactorType = 'CN'


select paymentYear, count(1) from [rev].[tbl_Summary_RskAdj_EDS_Preliminary]
--where paymentYear = 2020
group by paymentYear

select paymentYear, count(1) from ProdSupport.[dbo].[tbl_Summary_RskAdj_EDS_Preliminary]
where paymentYear = 2020
group by paymentYear


select top 10 * from [rev].[tbl_Summary_RskAdj_EDS_Preliminary]
where paymentYear = 2020

select * into ProdSupport.[dbo].[tbl_Summary_RskAdj_EDS_Preliminary]
from [rev].[tbl_Summary_RskAdj_EDS_Preliminary] 


select top 10 * from ProdSupport.[dbo].[tbl_Summary_RskAdj_EDS_Preliminary]
where paymentYear = 2020

-- Voided_by_MAO004ResponseDiagnosisCodeID
-- ContractID
-- RiskAdjustable, Deleted
select 
PlanIdentifier, PaymentYear, ModelYear, HICN, PartCRAFTProjected, MAO004ResponseID, stgMAO004ResponseID, SentEncounterICN, ReplacementEncounterSwitch, SentICNEncounterID, OriginalEncounterICN, OriginalICNEncounterID, PlanSubmissionDate, ServiceStartDate, ServiceEndDate, ClaimType, FileImportID, SentEncounterRiskAdjustableFlag, RiskAdjustableReasonCodes, OriginalEncounterRiskAdjustableFlag, MAO004ResponseDiagnosisCodeID, DiagnosisCode, DiagnosisICD, DiagnosisFlag, IsDelete, ClaimID, EntityDiscriminator, BaseClaimID, SecondaryClaimID, ClaimIndicator, RecordID, SystemSource, VendorID, MedicalRecordImageID, SubProjectMedicalRecordID, SubProjectID, SubProjectName, SupplementalID, DerivedPatientControlNumber, Void_Indicator, HCC_Label, HCC_Number, Matched
from ProdSupport.[dbo].[tbl_Summary_RskAdj_EDS_Preliminary]
where paymentYear = 2020

except

select 
PlanIdentifier, PaymentYear, ModelYear, HICN, PartCRAFTProjected, MAO004ResponseID, stgMAO004ResponseID, SentEncounterICN, ReplacementEncounterSwitch, SentICNEncounterID, OriginalEncounterICN, OriginalICNEncounterID, PlanSubmissionDate, ServiceStartDate, ServiceEndDate, ClaimType, FileImportID, SentEncounterRiskAdjustableFlag, RiskAdjustableReasonCodes, OriginalEncounterRiskAdjustableFlag, MAO004ResponseDiagnosisCodeID, DiagnosisCode, DiagnosisICD, DiagnosisFlag, IsDelete, ClaimID, EntityDiscriminator, BaseClaimID, SecondaryClaimID, ClaimIndicator, RecordID, SystemSource, VendorID, MedicalRecordImageID, SubProjectMedicalRecordID, SubProjectID, SubProjectName, SupplementalID, DerivedPatientControlNumber, Void_Indicator, HCC_Label, HCC_Number, Matched
from [etl].[tbl_Summary_RskAdj_EDS_Preliminary]
where paymentYear = 2020


select 
PlanIdentifier, PaymentYear, ModelYear, HICN, PartCRAFTProjected, MAO004ResponseID, stgMAO004ResponseID, SentEncounterICN, ReplacementEncounterSwitch, SentICNEncounterID, OriginalEncounterICN, OriginalICNEncounterID, PlanSubmissionDate, ServiceStartDate, ServiceEndDate, ClaimType, FileImportID, SentEncounterRiskAdjustableFlag, RiskAdjustableReasonCodes, OriginalEncounterRiskAdjustableFlag, MAO004ResponseDiagnosisCodeID, DiagnosisCode, DiagnosisICD, DiagnosisFlag, IsDelete, ClaimID, EntityDiscriminator, BaseClaimID, SecondaryClaimID, ClaimIndicator, RecordID, SystemSource, VendorID, MedicalRecordImageID, SubProjectMedicalRecordID, SubProjectID, SubProjectName, SupplementalID, DerivedPatientControlNumber, Void_Indicator, HCC_Label, HCC_Number, Matched
from [etl].[tbl_Summary_RskAdj_EDS_Preliminary]
where paymentYear = 2020

except

select 
PlanIdentifier, PaymentYear, ModelYear, HICN, PartCRAFTProjected, MAO004ResponseID, stgMAO004ResponseID, SentEncounterICN, ReplacementEncounterSwitch, SentICNEncounterID, OriginalEncounterICN, OriginalICNEncounterID, PlanSubmissionDate, ServiceStartDate, ServiceEndDate, ClaimType, FileImportID, SentEncounterRiskAdjustableFlag, RiskAdjustableReasonCodes, OriginalEncounterRiskAdjustableFlag, MAO004ResponseDiagnosisCodeID, DiagnosisCode, DiagnosisICD, DiagnosisFlag, IsDelete, ClaimID, EntityDiscriminator, BaseClaimID, SecondaryClaimID, ClaimIndicator, RecordID, SystemSource, VendorID, MedicalRecordImageID, SubProjectMedicalRecordID, SubProjectID, SubProjectName, SupplementalID, DerivedPatientControlNumber, Void_Indicator, HCC_Label, HCC_Number, Matched
from ProdSupport.[dbo].[tbl_Summary_RskAdj_EDS_Preliminary]
where paymentYear = 2020


select 
'Old' Format, PlanIdentifier, PaymentYear, ModelYear, HICN, PartCRAFTProjected, MAO004ResponseID, stgMAO004ResponseID, ContractID, SentEncounterICN, ReplacementEncounterSwitch, SentICNEncounterID, OriginalEncounterICN, OriginalICNEncounterID, PlanSubmissionDate, ServiceStartDate, ServiceEndDate, ClaimType, FileImportID, LoadID, LoadDate, SentEncounterRiskAdjustableFlag, RiskAdjustableReasonCodes, OriginalEncounterRiskAdjustableFlag, MAO004ResponseDiagnosisCodeID, DiagnosisCode, DiagnosisICD, DiagnosisFlag, IsDelete, ClaimID, EntityDiscriminator, BaseClaimID, SecondaryClaimID, ClaimIndicator, RecordID, SystemSource, VendorID, MedicalRecordImageID, SubProjectMedicalRecordID, SubProjectID, SubProjectName, SupplementalID, DerivedPatientControlNumber, Void_Indicator, Voided_by_MAO004ResponseDiagnosisCodeID, HCC_Label, HCC_Number, Matched
from ProdSupport.[dbo].[tbl_Summary_RskAdj_EDS_Preliminary]
where paymentYear = 2020
--and MAO004ResponseID = 5588852
and hicn = '1A66DX1WV41'

union
select 
'New' Format, PlanIdentifier, PaymentYear, ModelYear, HICN, PartCRAFTProjected, MAO004ResponseID, stgMAO004ResponseID, ContractID, SentEncounterICN, ReplacementEncounterSwitch, SentICNEncounterID, OriginalEncounterICN, OriginalICNEncounterID, PlanSubmissionDate, ServiceStartDate, ServiceEndDate, ClaimType, FileImportID, LoadID, LoadDate, SentEncounterRiskAdjustableFlag, RiskAdjustableReasonCodes, OriginalEncounterRiskAdjustableFlag, MAO004ResponseDiagnosisCodeID, DiagnosisCode, DiagnosisICD, DiagnosisFlag, IsDelete, ClaimID, EntityDiscriminator, BaseClaimID, SecondaryClaimID, ClaimIndicator, RecordID, SystemSource, VendorID, MedicalRecordImageID, SubProjectMedicalRecordID, SubProjectID, SubProjectName, SupplementalID, DerivedPatientControlNumber, Void_Indicator, Voided_by_MAO004ResponseDiagnosisCodeID, HCC_Label, HCC_Number, Matched
from [rev].[tbl_Summary_RskAdj_EDS_Preliminary]
where paymentYear = 2020
--and MAO004ResponseID = 5588852
and hicn = '1A66DX1WV41'

--------------------------------------------
select * into ProdSupport.[dbo].[tbl_Summary_RskAdj_EDS]
from [rev].[tbl_Summary_RskAdj_EDS]

select count(1) from [rev].[tbl_Summary_RskAdj_EDS]
where paymentYear = 2020

select LoadDateTime, paymentYear, count(1) from [rev].[tbl_Summary_RskAdj_EDS]
group by LoadDateTime, paymentYear

select count(1) from ProdSupport.[dbo].[tbl_Summary_RskAdj_EDS]
where paymentYear = 2020

select count(1) from [rev].[tbl_Summary_RskAdj_EDS]
where paymentYear = 2020

select top 10 * from [rev].[tbl_Summary_RskAdj_EDS]
where paymentYear = 2020

--Min_Processby_DiagCD, Min_ThruDate_DiagCD, 
--Min_ProcessBy_MAO004ResponseDiagnosisCodeId, Min_ThruDate_MAO004ResponseDiagnosisCodeId, 

select 
	PlanID, HICN, PaymentYear, PaymStart, Model_Year, Factor_category, Factor_Desc, Factor, RAFT, HCC_Number, Min_ProcessBy, Min_ThruDate, Min_ProcessBy_SeqNum, Min_ThruDate_SeqNum, Min_ProcessBy_PCN, Min_ThruDate_PCN, processed_priority_thru_date, thru_priority_processed_by, RAFT_ORIG, Processed_Priority_FileID, Processed_Priority_RAPS_Source_ID, Processed_Priority_Provider_ID, Processed_Priority_RAC, Thru_Priority_FileID, Thru_Priority_RAPS_Source_ID, Thru_Priority_Provider_ID, Thru_Priority_RAC, IMFFlag, Factor_Desc_ORIG, Factor_Desc_EstRecev, Aged, LastAssignedHICN
from ProdSupport.[dbo].[tbl_Summary_RskAdj_EDS]
where paymentYear = 2020

except

select 
	PlanID, HICN, PaymentYear, PaymStart, Model_Year, Factor_category, Factor_Desc, Factor, RAFT, HCC_Number, Min_ProcessBy, Min_ThruDate, Min_ProcessBy_SeqNum, Min_ThruDate_SeqNum, Min_ProcessBy_PCN, Min_ThruDate_PCN, processed_priority_thru_date, thru_priority_processed_by, RAFT_ORIG, Processed_Priority_FileID, Processed_Priority_RAPS_Source_ID, Processed_Priority_Provider_ID, Processed_Priority_RAC, Thru_Priority_FileID, Thru_Priority_RAPS_Source_ID, Thru_Priority_Provider_ID, Thru_Priority_RAC, IMFFlag, Factor_Desc_ORIG, Factor_Desc_EstRecev, Aged, LastAssignedHICN
from [rev].[tbl_Summary_RskAdj_EDS]
where paymentYear = 2020

select 
	PlanID, HICN, PaymentYear, PaymStart, Model_Year, Factor_category, Factor_Desc, Factor, RAFT, HCC_Number, Min_ProcessBy, Min_ThruDate, Min_ProcessBy_SeqNum, Min_ThruDate_SeqNum, Min_ProcessBy_PCN, Min_ThruDate_PCN, processed_priority_thru_date, thru_priority_processed_by, RAFT_ORIG, Processed_Priority_FileID, Processed_Priority_RAPS_Source_ID, Processed_Priority_Provider_ID, Processed_Priority_RAC, Thru_Priority_FileID, Thru_Priority_RAPS_Source_ID, Thru_Priority_Provider_ID, Thru_Priority_RAC, IMFFlag, Factor_Desc_ORIG, Factor_Desc_EstRecev, Aged, LastAssignedHICN
from [rev].[tbl_Summary_RskAdj_EDS]
where paymentYear = 2020

except

select 
	PlanID, HICN, PaymentYear, PaymStart, Model_Year, Factor_category, Factor_Desc, Factor, RAFT, HCC_Number, Min_ProcessBy, Min_ThruDate, Min_ProcessBy_SeqNum, Min_ThruDate_SeqNum, Min_ProcessBy_PCN, Min_ThruDate_PCN, processed_priority_thru_date, thru_priority_processed_by, RAFT_ORIG, Processed_Priority_FileID, Processed_Priority_RAPS_Source_ID, Processed_Priority_Provider_ID, Processed_Priority_RAC, Thru_Priority_FileID, Thru_Priority_RAPS_Source_ID, Thru_Priority_Provider_ID, Thru_Priority_RAC, IMFFlag, Factor_Desc_ORIG, Factor_Desc_EstRecev, Aged, LastAssignedHICN
from ProdSupport.[dbo].[tbl_Summary_RskAdj_EDS]
where paymentYear = 2020




select 
	PlanID, HICN, PaymentYear, PaymStart, Model_Year, Factor_category, Factor_Desc, Factor, RAFT, HCC_Number, Min_ProcessBy, Min_ThruDate, Min_ProcessBy_SeqNum, Min_ThruDate_SeqNum, Min_Processby_DiagCD, Min_ThruDate_DiagCD, Min_ProcessBy_PCN, Min_ThruDate_PCN, processed_priority_thru_date, thru_priority_processed_by, RAFT_ORIG, Processed_Priority_FileID, Processed_Priority_RAPS_Source_ID, Processed_Priority_Provider_ID, Processed_Priority_RAC, Thru_Priority_FileID, Thru_Priority_RAPS_Source_ID, Thru_Priority_Provider_ID, Thru_Priority_RAC, IMFFlag, Factor_Desc_ORIG, Factor_Desc_EstRecev, Min_ProcessBy_MAO004ResponseDiagnosisCodeId, Min_ThruDate_MAO004ResponseDiagnosisCodeId, Aged, LastAssignedHICN
from ProdSupport.[dbo].[tbl_Summary_RskAdj_EDS]
where paymentYear = 2020
and HICN = '1A66DX1WV41'
and HCC_Number in (1, 2, 58, 59)

select 
	PlanID, HICN, PaymentYear, PaymStart, Model_Year, Factor_category, Factor_Desc, Factor, RAFT, HCC_Number, Min_ProcessBy, Min_ThruDate, Min_ProcessBy_SeqNum, Min_ThruDate_SeqNum, Min_Processby_DiagCD, Min_ThruDate_DiagCD, Min_ProcessBy_PCN, Min_ThruDate_PCN, processed_priority_thru_date, thru_priority_processed_by, RAFT_ORIG, Processed_Priority_FileID, Processed_Priority_RAPS_Source_ID, Processed_Priority_Provider_ID, Processed_Priority_RAC, Thru_Priority_FileID, Thru_Priority_RAPS_Source_ID, Thru_Priority_Provider_ID, Thru_Priority_RAC, IMFFlag, Factor_Desc_ORIG, Factor_Desc_EstRecev, Min_ProcessBy_MAO004ResponseDiagnosisCodeId, Min_ThruDate_MAO004ResponseDiagnosisCodeId, Aged, LastAssignedHICN
from [rev].[tbl_Summary_RskAdj_EDS]
where paymentYear = 2020
and HICN = '1A66DX1WV41'
and HCC_Number in (1, 2, 58, 59)

select * from hrpreporting.dbo.lkRiskModelsFactors
where PaymentYear = 2020

select 
	PlanID, HICN, PaymentYear, PaymStart, Model_Year, Factor_category, Factor_Desc, Factor, RAFT, HCC_Number, Min_ProcessBy, Min_ThruDate, Min_ProcessBy_SeqNum, Min_ThruDate_SeqNum, Min_Processby_DiagCD, Min_ThruDate_DiagCD, Min_ProcessBy_PCN, Min_ThruDate_PCN, processed_priority_thru_date, thru_priority_processed_by, RAFT_ORIG, Processed_Priority_FileID, Processed_Priority_RAPS_Source_ID, Processed_Priority_Provider_ID, Processed_Priority_RAC, Thru_Priority_FileID, Thru_Priority_RAPS_Source_ID, Thru_Priority_Provider_ID, Thru_Priority_RAC, IMFFlag, Factor_Desc_ORIG, Factor_Desc_EstRecev, Min_ProcessBy_MAO004ResponseDiagnosisCodeId, Min_ThruDate_MAO004ResponseDiagnosisCodeId, Aged, LastAssignedHICN
from ProdSupport.[dbo].[tbl_Summary_RskAdj_EDS]
where paymentYear = 2020
and RAFT = 'D'

select 
	PlanID, HICN, PaymentYear, PaymStart, Model_Year, Factor_category, Factor_Desc, Factor, RAFT, HCC_Number, Min_ProcessBy, Min_ThruDate, Min_ProcessBy_SeqNum, Min_ThruDate_SeqNum, Min_Processby_DiagCD, Min_ThruDate_DiagCD, Min_ProcessBy_PCN, Min_ThruDate_PCN, processed_priority_thru_date, thru_priority_processed_by, RAFT_ORIG, Processed_Priority_FileID, Processed_Priority_RAPS_Source_ID, Processed_Priority_Provider_ID, Processed_Priority_RAC, Thru_Priority_FileID, Thru_Priority_RAPS_Source_ID, Thru_Priority_Provider_ID, Thru_Priority_RAC, IMFFlag, Factor_Desc_ORIG, Factor_Desc_EstRecev, Min_ProcessBy_MAO004ResponseDiagnosisCodeId, Min_ThruDate_MAO004ResponseDiagnosisCodeId, Aged, LastAssignedHICN
from [rev].[tbl_Summary_RskAdj_EDS]
where paymentYear = 2020
and RAFT = 'D'


---------------------------------
select count(1) from [rev].[tbl_Summary_RskAdj_RAPS_Preliminary]
where paymentYear = 2020

select count(1) from ProdSupport.[dbo].[tbl_Summary_RskAdj_RAPS_Preliminary]
where paymentYear = 2020

select LoadDateTime, count(1) from ProdSupport.[dbo].[tbl_Summary_RskAdj_RAPS_Preliminary]
where paymentYear = 2020
group by LoadDateTime


select LoadDateTime, count(1) from [rev].[tbl_Summary_RskAdj_RAPS_Preliminary]
where paymentYear = 2020
group by LoadDateTime




select count(1) from [rev].[tbl_Summary_RskAdj_RAPS]
where paymentYear = 2020

select count(1) from ProdSupport.[dbo].[tbl_Summary_RskAdj_RAPS]
where paymentYear = 2020

select LoadDateTime, count(1) from ProdSupport.[dbo].[tbl_Summary_RskAdj_RAPS]
where paymentYear = 2020
group by LoadDateTime


select LoadDateTime, count(1) from [rev].[tbl_Summary_RskAdj_RAPS]
where paymentYear = 2020
group by LoadDateTime



select 
	PlanID, HICN, PaymentYear, PaymStart, Factor_category, Factor_Desc, Factor, RAFT, HCC_Number, Min_ProcessBy, Min_ThruDate, Min_ProcessBy_SeqNum, Min_ThruDate_SeqNum, Min_Processby_DiagCD, Min_ThruDate_DiagCD, Min_ProcessBy_PCN, Min_ThruDate_PCN, Processed_Priority_Thru_Date, Thru_Priority_Processed_By, RAFT_ORIG, Processed_Priority_FileID, Processed_Priority_RAPS_Source_ID, Processed_Priority_Provider_ID, Processed_Priority_RAC, Thru_Priority_FileID, Thru_Priority_RAPS_Source_ID, Thru_Priority_Provider_ID, Thru_Priority_RAC, IMFFlag, Factor_Desc_ORIG, Aged
from ProdSupport.[dbo].[tbl_Summary_RskAdj_RAPS]
where paymentYear = 2020

except

select 
	PlanID, HICN, PaymentYear, PaymStart, Factor_category, Factor_Desc, Factor, RAFT, HCC_Number, Min_ProcessBy, Min_ThruDate, Min_ProcessBy_SeqNum, Min_ThruDate_SeqNum, Min_Processby_DiagCD, Min_ThruDate_DiagCD, Min_ProcessBy_PCN, Min_ThruDate_PCN, Processed_Priority_Thru_Date, Thru_Priority_Processed_By, RAFT_ORIG, Processed_Priority_FileID, Processed_Priority_RAPS_Source_ID, Processed_Priority_Provider_ID, Processed_Priority_RAC, Thru_Priority_FileID, Thru_Priority_RAPS_Source_ID, Thru_Priority_Provider_ID, Thru_Priority_RAC, IMFFlag, Factor_Desc_ORIG, Aged
from [rev].[tbl_Summary_RskAdj_RAPS]
where paymentYear = 2020


select 
	*
from ProdSupport.[dbo].[tbl_Summary_RskAdj_RAPS]
where paymentYear = 2020
and hicn = '1A04QM1CH84 '
and Factor_Desc = 'HCC 12'
and PaymStart = '2020-06-01 00:00:00.000'

union

select 
	*
from [rev].[tbl_Summary_RskAdj_RAPS]
where paymentYear = 2020
and hicn = '1A04QM1CH84 '
and Factor_Desc = 'HCC 12'
and PaymStart = '2020-06-01 00:00:00.000'


select 
	distinct paymentyear, RAfactortype, partcdflag, demorisktype, factordescription, gender, factor, aged,  Modelversion
from 
	HRPReporting.[dbo].lkRiskModelsFactors
where 
	PaymentYear in (2017, 2018, 2019, 2020)
	and RAFactorType = 'CN'
	and Aged = 1
	and factorDescription = 'HCC 12'
order by PaymentYear

select 
	distinct payment_year, factor_type, part_c_d_flag, demo_risk_type, factor_description, gender, factor, aged
from 
	HRPReporting.[dbo].lk_Risk_Models
where 
	Payment_Year in (2017, 2018, 2019, 2020)
	and Factor_Type = 'CN'
	and Aged = 1
	and factor_Description = 'HCC 12'
order by Payment_Year

select 
	PaymentYear, ModelYear, RecordType, RAFactorType, Version, SubmissionModel, APCCFlag
from [HRPReporting].[dbo].[lk_Risk_Score_Factors_PartC]
where 
	PaymentYear in (2017, 2018, 2019, 2020)
	and RAFactorType = 'CN'

select 
	PaymentYear, RecordType, RAFactorType, ModelVersion, SubmissionModel, APCCFlag
from HRPReporting.[dbo].lkRiskModelsMaster
where 
	PaymentYear in (2017, 2018, 2019, 2020)
	and RAFactorType = 'CN'


select * from [dbo].[lkRiskModelsFactors]


select 
	distinct paymentyear, RAfactortype, partcdflag, demorisktype, factordescription, gender, factor, aged, ModelVersion, submissionmodel
from 
	HRPReporting.[dbo].[lkRiskModelsFactors]
where 
	PaymentYear in (2017, 2018, 2019, 2020)
	and RAFactorType = 'CN'
	and Aged = 1
	and factorDescription = 'HCC 12'
order by PaymentYear


select 
	distinct payment_year, factor_type, part_c_d_flag, demo_risk_type, factor_description, gender, factor, aged
from 
	HRPReporting.[dbo].lk_Risk_Models
where 
	Payment_Year in (2017, 2018, 2019, 2020)
	and Factor_Type = 'CN'
	and Aged = 1
	and factor_Description = 'HCC 12'
order by Payment_Year

use HRPReporting


select * from [dbo].[lkRiskModelsFactors]
select * from dbo.[lkRiskModelsMaster]

alter table [dbo].[lkRiskModelsFactors] add [SubmissionModel] [varchar](5) NULL

select * from [dbo].[lk_Risk_Score_Factors_PartC] where paymentYear = 2019
and RAFactorType in ('CN','CP','CF','I')

select * from [dbo].[lkRiskModelsFactors] where paymentYear = 2019 and RAFactorType = 'CN'


select * from [dbo].[lkRiskModelsFactors] where paymentYear = 2019 and RAFactorType in ('CN','CP','CF','I')

update [dbo].[lkRiskModelsFactors] set SubmissionModel = 'RAPS' where paymentYear = 2019 and RAFactorType in ('CN','CP','CF','I')


INSERT INTO [dbo].[lkRiskModelsFactors] (
	 [PaymentYear] 
	,[ModelVersion]
	,[RAFactorType]
	,[PartCDFlag]	
	,[OREC]
	,[LI]
	,[MedicaidFlag]	
	,[DemoRiskType]
	,[FactorDescription]
	,[HCCNumber]
	,[Gender]
	,[Factor] 
	,[Aged]
	,[APCCFlag]
	,[LoadID] 
	,[LoadDate]
	,SubmissionModel
)
select 
	 [PaymentYear] 
	,[ModelVersion]
	,[RAFactorType]
	,[PartCDFlag]	
	,[OREC]
	,[LI]
	,[MedicaidFlag]	
	,[DemoRiskType]
	,[FactorDescription]
	,[HCCNumber]
	,[Gender]
	,[Factor] 
	,[Aged]
	,[APCCFlag]
	,[LoadID] 
	,[LoadDate]
	,'EDS'
FROM
	[dbo].[lkRiskModelsFactors]
where paymentYear = 2019 and RAFactorType in ('CN','CP','CF','I') and SubmissionModel = 'RAPS'

