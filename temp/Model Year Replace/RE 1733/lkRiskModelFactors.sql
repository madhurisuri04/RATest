
--drop table [ProdSupport].[dbo].[lkRiskModelsFactors]
CREATE TABLE [ProdSupport].[dbo].[lkRiskModelsFactors](
	[lkRiskModelsFactorsID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PaymentYear] [int] NOT NULL,
	[ModelVersion] [smallint] NULL,
	[FactorType] [varchar](10) NULL,
	[PartCDFlag] [varchar](1) NULL,
	[OREC] [int] NULL,
	[LI] [int] NULL,
	[MedicaidFlag] [int] NULL,
	[DemoRiskType] [varchar](10) NULL,
	[FactorDescription] [varchar](50) NULL,
	[HCCNumber] [varchar](4) NULL,
	[Gender] [int] NULL,
	[Factor] [decimal](20, 4) NULL,
	[Aged] [int] NULL, 
	[APCCFlag] [char](1) NULL,
	[LoadID] [bigint] NOT NULL,
	[LoadDate] [datetime] NOT NULL,
 CONSTRAINT [PK_lkRiskModelsFactorsID] PRIMARY KEY CLUSTERED 
(
	[lkRiskModelsFactorsID] ASC
)
)



--------------------------
drop table #combination
select distinct paymentyear, RAFactorType, ModelVersion, APCCFlag
into #combination
from [ProdSupport].[dbo].[lkRiskModelsMaster]
where paymentyear > 2016


select * from #combination

--------------------------

--truncate table [ProdSupport].[dbo].[lkRiskModelsFactors]
INSERT INTO [ProdSupport].[dbo].[lkRiskModelsFactors] (
	[PaymentYear] 
	,[ModelVersion]
	,[FactorType]
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
)
select 
	[Payment_Year] 
	,c.[ModelVersion]
	,[Factor_Type]
	,[Part_C_D_Flag]	
	,[OREC]
	,[LI]
	,[Medicaid_Flag]	
	,[Demo_Risk_Type]
	,[Factor_Description]
	,[HCCNumber] = cast(cast (case when [Demo_Risk_Type] = 'RISK' then LTRIM(REVERSE(LEFT(REVERSE([Factor_Description]), PATINDEX('%[A-Z]%',REVERSE([Factor_Description])) - 1))) else null end as int) as varchar)
	,[Gender]
	,[Factor] 
	,[Aged]
	,c.[APCCFlag]
	,0
	,getdate()
from HRPReporting.dbo.lk_risk_models lk
join #combination c
on lk.Payment_Year = c.PaymentYear
and lk.Factor_Type = c.RAFactorType
where Payment_Year > 2016

INSERT INTO [ProdSupport].[dbo].[lkRiskModelsFactors] (
	[PaymentYear] 
	,[ModelVersion]
	,[FactorType]
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
)
select 
	[Payment_Year] 
	,[ModelVersion] = 5
	,[Factor_Type]
	,[Part_C_D_Flag]	
	,[OREC]
	,[LI]
	,[Medicaid_Flag]	
	,[Demo_Risk_Type]
	,[Factor_Description]
	,[HCCNumber] = cast(cast (case when [Demo_Risk_Type] = 'RISK' then LTRIM(REVERSE(LEFT(REVERSE([Factor_Description]), PATINDEX('%[A-Z]%',REVERSE([Factor_Description])) - 1))) else null end as int) as varchar)
	,[Gender]
	,[Factor] 
	,[Aged]
	,'N'
	,0
	,getdate()
from HRPReporting.dbo.lk_risk_models lk
where Payment_Year > 2016
and Factor_Type in ('D4','D5','D6','D7','D8','D9')

update [ProdSupport].[dbo].[lkRiskModelsFactors]
set DemoRiskType = 'APCC',
HCCNumber = null
where
FactorDescription in ('D1','D2','D3','D4','D5','D6','D7','D8','D9','D10P','D10')


/* 
/* TEST */

select PaymentYear, FactorType, PartCDFlag, OREC, LI, MedicaidFlag, DemoRiskType, FactorDescription, GEnder, Factor, Aged from [ProdSupport].[dbo].[lkRiskModelsFactors]
except
select Payment_Year, Factor_Type, Part_C_D_Flag, OREC, LI, Medicaid_Flag, Demo_Risk_Type, Factor_Description, GEnder, Factor, Aged from HRPReporting.dbo.lk_risk_models
where Payment_Year > 2016

select Payment_Year, Factor_Type, Part_C_D_Flag, OREC, LI, Medicaid_Flag, Demo_Risk_Type, Factor_Description, GEnder, Factor, Aged from HRPReporting.dbo.lk_risk_models
where Payment_Year > 2016
except
select PaymentYear, FactorType, PartCDFlag, OREC, LI, MedicaidFlag, DemoRiskType, FactorDescription, GEnder, Factor, Aged from [ProdSupport].[dbo].[lkRiskModelsFactors]

select * from [ProdSupport].[dbo].[lkRiskModelsFactors]
where factordescription like 'D%'
*/

