select * from HRPReporting.dbo.lk_risk_models
where Payment_Year in (2021, 2020)

CREATE TABLE #temp_lkRiskModelsFactors (
	[lkRiskModelsFactorsID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[Payment_Year] [int] NOT NULL,
	[ModelVersion] [smallint] NULL,
	[Part_C_D_Flag] [varchar](1) NULL,
	[Factor_Type] [varchar](10) NULL,
	[Aged] [int] NULL,
	[OREC] [int] NULL,
	[LI] [int] NULL,
	[Medicaid_Flag] [int] NULL,
	[Gender] [int] NULL,
	[Demo_Risk_Type] [varchar](10) NULL,
	[Factor_Description] [varchar](50) NULL,
	[Factor] [decimal](20, 4) NULL,
	CONSTRAINT [PK_lkRiskModelsFactors_lkRiskModelsFactorsID] PRIMARY KEY CLUSTERED 
	(
		[lkRiskModelsFactorsID] ASC
	)
)

--------------------------
--2020 PY
--------------------------

--RAPS Part C (non-ESRD) ONLY
--2020 PY ONLY
INSERT INTO #temp_lkRiskModelsFactors (
	[Payment_Year] 
	,[ModelVersion]
	,[Part_C_D_Flag]
	,[Factor_Type]
	,[Aged]
	,[OREC]
	,[LI]
	,[Medicaid_Flag]
	,[Gender]
	,[Demo_Risk_Type]
	,[Factor_Description]
	,[Factor] 
)
select 
	Payment_Year
	,22 as ModelVersion
	,Part_C_D_Flag 
	,Factor_Type
	,Aged
	,OREC
	,LI
	,Medicaid_Flag
	,Gender
	,Demo_Risk_Type
	,Factor_Description
	,Factor
from HRPReporting.dbo.lk_risk_models
where Payment_Year in (2020)
and Part_C_D_Flag = 'C'
and Factor_Type in ('CF', 'CN', 'CP',  'I', 'E', 'SE') 

--EDS Part C and Part D, incl ESRD
--2020 PY ONLY
INSERT INTO #temp_lkRiskModelsFactors (
	[Payment_Year] 
	,[ModelVersion]
	,[Part_C_D_Flag]
	,[Factor_Type]
	,[Aged]
	,[OREC]
	,[LI]
	,[Medicaid_Flag]
	,[Gender]
	,[Demo_Risk_Type]
	,[Factor_Description]
	,[Factor] 
)
select 
	Payment_Year
	,case when   (Part_C_D_Flag = 'C' and Factor_Type in ('CF', 'CN', 'CP',  'I', 'E', 'SE') and Payment_Year = 2020) then 24
			when (Part_C_D_Flag = 'C' and Factor_Type in ('D', 'ED', 'C1',  'C2', 'I1', 'I2', 'E1', 'E2', 'G1', 'G2') and Payment_Year = 2020) then 21
			when (Part_C_D_Flag = 'D' and Payment_Year = 2020) then 5
	end as ModelVersion
	,Part_C_D_Flag 
	,Factor_Type
	,Aged
	,OREC
	,LI
	,Medicaid_Flag
	,Gender
	,Demo_Risk_Type
	,Factor_Description
	,Factor
from HRPReporting.dbo.lk_risk_models
where Payment_Year in (2020)


--------------------------
--2021 PY
--------------------------

--RAPS Part C (non-ESRD) ONLY
--2021 PY ONLY
INSERT INTO #temp_lkRiskModelsFactors (
	[Payment_Year] 
	,[ModelVersion]
	,[Part_C_D_Flag]
	,[Factor_Type]
	,[Aged]
	,[OREC]
	,[LI]
	,[Medicaid_Flag]
	,[Gender]
	,[Demo_Risk_Type]
	,[Factor_Description]
	,[Factor] 
)
select 
	Payment_Year
	,22 as ModelVersion
	,Part_C_D_Flag 
	,Factor_Type
	,Aged
	,OREC
	,LI
	,Medicaid_Flag
	,Gender
	,Demo_Risk_Type
	,Factor_Description
	,Factor
from HRPReporting.dbo.lk_risk_models
where Payment_Year in (2021)
and Part_C_D_Flag = 'C'
and Factor_Type in ('CF', 'CN', 'CP',  'I', 'E', 'SE') 


--EDS Part C and Part D, incl ESRD
--2021 PY ONLY
INSERT INTO #temp_lkRiskModelsFactors (
	[Payment_Year] 
	,[ModelVersion]
	,[Part_C_D_Flag]
	,[Factor_Type]
	,[Aged]
	,[OREC]
	,[LI]
	,[Medicaid_Flag]
	,[Gender]
	,[Demo_Risk_Type]
	,[Factor_Description]
	,[Factor] 
)
select 
	Payment_Year
	,case when (Part_C_D_Flag = 'C' and Factor_Type in ('CF', 'CN', 'CP',  'I', 'E', 'SE') and Payment_Year = 2021) then 24
			when (Part_C_D_Flag = 'C' and Factor_Type in ('D', 'ED', 'C1',  'C2', 'I1', 'I2', 'E1', 'E2', 'G1', 'G2') and Payment_Year = 2021) then 21
			when (Part_C_D_Flag = 'D' and Payment_Year = 2021) then 5
	end as ModelVersion
	,Part_C_D_Flag 
	,Factor_Type
	,Aged
	,OREC
	,LI
	,Medicaid_Flag
	,Gender
	,Demo_Risk_Type
	,Factor_Description
	,Factor
from HRPReporting.dbo.lk_risk_models
where Payment_Year in (2021)


drop table #temp_lkRiskModelsFactors


select * from #temp_lkRiskModelsFactors
where ModelVersion is NULL