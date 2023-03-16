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
--truncate table [ProdSupport].[dbo].[lkRiskModelsInteraction]

INSERT INTO [dbo].[lkRiskModelsInteraction](
	[PaymentYear] ,
	[ModelVersion] ,
	[InteractionLabel] ,
	[HCCLabel1] ,
	[HCCLabel2] ,
	[HCCLabel3] ,
	[HCCNumber1] ,
	[HCCNumber2] ,
	[HCCNumber3] ,
	[FactorType] ,
	[LongDescription] ,
	[ShortDescription] , 
    [LoadID] ,
	[LoadDate] 
)
select distinct
	[Payment_Year] = b.payment_year,
	[ModelVersion] = c.[ModelVersion],
	[InteractionLabel] = b.interaction_label,
	[HCCLabel1] = b.hcc_label_1,
	[HCCLabel2] = b.hcc_label_2,
	[HCCLabel3] = b.hcc_label_3,
	[HCCNumber1] = b.hcc_number_1,
	[HCCNumber2] = b.hcc_number_2,
	[HCCNumber3] = b.hcc_number_3,
	[FactorType] = b.factor_type,
	[LongDescription] = b.long_description,
	[ShortDescription] = b.short_description, 
	[LoadID] = 0,
	[LoadDate] = getdate()
from HRPReporting.dbo.lk_Risk_Models_Interactions b
	join #combination c
	on b.Payment_Year = c.PaymentYear
	and b.FACTOR_TYPE = c.RAFactorType
where 
	Payment_Year > 2016

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

