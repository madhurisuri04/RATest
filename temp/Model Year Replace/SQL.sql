use php_report

CREATE TABLE [#Refresh_PY]
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY,
    [Payment_Year] INT NOT NULL,
    [From_Date] SMALLDATETIME NULL,
    [Thru_Date] SMALLDATETIME NULL,
    [Lagged_From_Date] SMALLDATETIME NULL,
    [Lagged_Thru_Date] SMALLDATETIME NULL
);


INSERT INTO [#Refresh_PY]
(
    [Payment_Year],
    [From_Date],
    [Thru_Date],
    [Lagged_From_Date],
    [Lagged_Thru_Date]
)
SELECT [Payment_Year] = [a1].[Payment_Year],
       [From_Date] = [a1].[From_Date],
       [Thru_Date] = [a1].[Thru_Date],
       [Lagged_From_Date] = [a1].[Lagged_From_Date],
       [Lagged_Thru_Date] = [a1].[Lagged_Thru_Date]
FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [a1];


select a.*,b.* from prodsupport.dbo.lkRiskModelsMaster a
join [#Refresh_PY] b
on a.PaymentYear = b.Payment_Year

select
	a.PaymentYear,
	a.PartCDFlag,
	a.RAFactorType,
	a.ModelVersion,
	a.SubmissionModel,
	a.SubmissionModelNumber,
	a.APCCFlag
into #lkRiskModelsMaster
from prodsupport.dbo.lkRiskModelsMaster a
join [#Refresh_PY] b
on a.PaymentYear = b.Payment_Year

select * from #lkRiskModelsMaster

drop table [#Vw_LkRiskModelsDiagHCC]
SELECT DISTINCT
       [PaymentYear] = [icd].[PaymentYear],
       [FactorType] = [icd].[FactorType],
	   [ModelVersion] = [icd].[ModelVersion],
       [ICDCode] = [icd].[ICD10CD],
       [HCCLabel] = [icd].[HCCLabel]
INTO [#Vw_LkRiskModelsDiagHCC]
FROM ProdSupport.[dbo].lkRiskModelsDiagHCC [icd]
JOIN #lkRiskModelsMaster lkm
on icd.PaymentYear = lkm.PaymentYear
and icd.FactorType = lkm.RAFactorType
and icd.ModelVersion = lkm.ModelVersion
and lkm.SubmissionModel = 'RAPS'

select * from [#Vw_LkRiskModelsDiagHCC]

select * FROM ProdSupport.[dbo].lkRiskModelsFactors 

drop table [#lkRiskModelsFactors]
SELECT DISTINCT
       f.PaymentYear,
       f.FactorType,
	   f.ModelVersion,
	   f.PartCDFlag,
	   f.OREC,
	   f.LI,
	   f.MedicaidFlag,
	   f.DemoRiskType,
	   f.FactorDescription,
	   f.Gender,
	   f.Factor,
	   f.Aged
INTO [#lkRiskModelsFactors]
FROM ProdSupport.[dbo].lkRiskModelsFactors f
JOIN #lkRiskModelsMaster lkm
on f.PaymentYear = lkm.PaymentYear
and f.FactorType = lkm.RAFactorType
and f.ModelVersion = lkm.ModelVersion
--and lkm.SubmissionModel = 'RAPS'
and lkm.SubmissionModel = 'EDS'

select paymentyear, factorType, modelversion, count(2) from [#lkRiskModelsFactors]
group by paymentyear, factorType, modelversion
order by 1,2,3


select * FROM ProdSupport.[dbo].lkRiskModelsHierarchy

drop table [#lkRiskModelsHierarchy]
SELECT DISTINCT
       h.PaymentYear,
       h.FactorType,
	   h.ModelVersion,
	   h.PartCDFlag,
	   h.HCCKeep,
	   h.HCCDrop,
	   h.HCCKeepNumber,
	   h.HCCDropNumber
INTO [#lkRiskModelsHierarchy]
FROM ProdSupport.[dbo].lkRiskModelsHierarchy h
JOIN #lkRiskModelsMaster lkm
on h.PaymentYear = lkm.PaymentYear
and h.FactorType = lkm.RAFactorType
and h.ModelVersion = lkm.ModelVersion
and lkm.SubmissionModel = 'RAPS'

select * from [#lkRiskModelsHierarchy]

select * from ProdSupport.[dbo].lkRiskModelsInteraction

drop table lkRiskModelsInteractions
SELECT DISTINCT
       i.PaymentYear,
       i.FactorType,
	   i.ModelVersion,
	   i.InteractionLabel,
	   i.HCCLabel1,
	   i.HCCLabel2,
	   i.HCCLabel3,
	   i.HCCNumber1,
	   i.HCCNumber2,
	   i.HCCNumber3,
	   i.LongDescription,
	   i.ShortDescription
INTO lkRiskModelsInteractions
FROM ProdSupport.[dbo].lkRiskModelsInteraction i
JOIN #lkRiskModelsMaster lkm
on i.PaymentYear = lkm.PaymentYear
and i.FactorType = lkm.RAFactorType
and i.ModelVersion = lkm.ModelVersion
and lkm.SubmissionModel = 'RAPS'

select * from lkRiskModelsInteractions
