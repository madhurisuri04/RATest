use HRPReporting

--drop table [ProdSupport].[dbo].[lkRiskModelsHierarchy]
CREATE TABLE [ProdSupport].[dbo].[lkRiskModelsHierarchy](
	[lkRiskModelsHierarchyID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PartCDFlag] [varchar](2) NOT NULL,
	[FACTORTYPE] [varchar](2) NOT NULL,
	[PaymentYear] [INT] NOT NULL,
	[ModelVersion] [smallint] NULL,
	[HCCKEEP] [varchar](50) NOT NULL,
	[HCCDROP] [varchar](50) NOT NULL,
	[HCCKEEPNUMBER] [varchar](50) NOT NULL,
	[HCCDROPNUMBER] [varchar](50) NOT NULL, 
    [LoadID] [bigint] NOT NULL,
	[LoadDate] [datetime] NOT NULL,
 CONSTRAINT [PK_lkRiskModelsHierarchyID] PRIMARY KEY CLUSTERED 
(
	[lkRiskModelsHierarchyID] ASC
)
) 



--------------------------
drop table #combination
select distinct paymentyear, RAFactorType, ModelVersion 
into #combination
from [ProdSupport].[dbo].[lkRiskModelsMaster]
where paymentyear > 2016
and RAFactorType in ('CN','CP','CF','I','C1','C2','I1','I2','D','D1','D2','D3','G1','G2')


--select * from #combination

--------------------------

truncate table [ProdSupport].[dbo].[lkRiskModelsHierarchy]

INSERT INTO [ProdSupport].[dbo].[lkRiskModelsHierarchy](
	[PartCDFlag] , 
	[RAFactorType] , 
	[PaymentYear],
	[ModelVersion] , 
	[HCCKEEP], 
	[HCCDROP], 
	[HCCKEEPNUMBER] , 
	[HCCDROPNUMBER] ,
	[LoadID] ,
	[LoadDate]  
)
select 
	b.[Part_C_D_Flag],
	b.[RA_FACTOR_TYPE] ,
	b.[Payment_Year]  ,
	[ModelVersion] = c.[ModelVersion],
	b.[HCC_KEEP],
	b.[HCC_DROP],
	b.[HCC_KEEP_NUMBER] ,
	b.[HCC_DROP_NUMBER] ,
	0,
	getdate()
from HRPReporting.dbo.lk_Risk_Models_Hierarchy b
	join #combination c
	on b.Payment_Year = c.PaymentYear
	and b.RA_FACTOR_TYPE = c.RAFactorType
where 
	Payment_Year > 2016
Group by 
	b.[Part_C_D_Flag],
	b.[RA_FACTOR_TYPE],
	b.[Payment_Year],
	c.[ModelVersion],
	b.[HCC_KEEP],
	b.[HCC_DROP],
	b.[HCC_KEEP_NUMBER],
	b.[HCC_DROP_NUMBER]


/* 
/* TEST */

select * from [ProdSupport].[dbo].[lkRiskModelsHierarchy]

select Payment_Year, Factor_Type, Part_C_D_Flag, OREC, LI, Medicaid_Flag, Demo_Risk_Type, Factor_Description, GEnder, Factor, Aged from [ProdSupport].[dbo].[lkRiskModelsFactors]
except
select Payment_Year, Factor_Type, Part_C_D_Flag, OREC, LI, Medicaid_Flag, Demo_Risk_Type, Factor_Description, GEnder, Factor, Aged from HRPReporting.dbo.lk_risk_models
where Payment_Year > 2016

select Payment_Year, Factor_Type, Part_C_D_Flag, OREC, LI, Medicaid_Flag, Demo_Risk_Type, Factor_Description, GEnder, Factor, Aged from HRPReporting.dbo.lk_risk_models
where Payment_Year > 2016
except
select Payment_Year, Factor_Type, Part_C_D_Flag, OREC, LI, Medicaid_Flag, Demo_Risk_Type, Factor_Description, GEnder, Factor, Aged from [ProdSupport].[dbo].[lkRiskModelsFactors]
*/



