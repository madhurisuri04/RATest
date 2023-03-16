use HRPReporting


--------------------------
drop table #combination
select distinct paymentyear, RAFactorType, ModelVersion 
into #combination
from [dbo].[lkRiskModelsMaster]
where paymentyear > 2016
and RAFactorType in ('CN','CP','CF','I','C1','C2','I1','I2','D','D1','D2','D3')


select * from #combination

--------------------------

--truncate table [dbo].[lkRiskModelsHierarchy]

INSERT INTO [dbo].[lkRiskModelsHierarchy](
	[PartCDFlag] , 
	[FACTORTYPE] , 
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

select Payment_Year, Factor_Type, Part_C_D_Flag, OREC, LI, Medicaid_Flag, Demo_Risk_Type, Factor_Description, GEnder, Factor, Aged from [dbo].[lkRiskModelsFactors]
except
select Payment_Year, Factor_Type, Part_C_D_Flag, OREC, LI, Medicaid_Flag, Demo_Risk_Type, Factor_Description, GEnder, Factor, Aged from HRPReporting.dbo.lk_risk_models
where Payment_Year > 2016

select Payment_Year, Factor_Type, Part_C_D_Flag, OREC, LI, Medicaid_Flag, Demo_Risk_Type, Factor_Description, GEnder, Factor, Aged from HRPReporting.dbo.lk_risk_models
where Payment_Year > 2016
except
select Payment_Year, Factor_Type, Part_C_D_Flag, OREC, LI, Medicaid_Flag, Demo_Risk_Type, Factor_Description, GEnder, Factor, Aged from [dbo].[lkRiskModelsFactors]
*/



