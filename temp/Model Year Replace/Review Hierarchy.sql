use HRPReporting
----create [lkRiskModelsHierarchy] table
CREATE TABLE [#lkRiskModelsHierarchy]
( [lkRiskModelsHierarchy_ID] [int] 
IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
[Part_C_D_Flag] [varchar](2) NOT NULL, 
[RA_FACTOR_TYPE] [varchar](2) NOT NULL, 
[Payment_Year] [INT] NOT NULL,
[ModelVersion] [smallint] NULL, 
[HCC_KEEP] [varchar](50) NOT NULL, 
[HCC_DROP] [varchar](50) NOT NULL, 
[HCC_KEEP_NUMBER] [varchar](50) NOT NULL, 
[HCC_DROP_NUMBER] [varchar](50) NOT NULL, 

)
Truncate table [#lkRiskModelsHierarchy]
INSERT INTO [#lkRiskModelsHierarchy](
[Part_C_D_Flag] , 
[RA_FACTOR_TYPE] , 
[Payment_Year],
[ModelVersion] , 
[HCC_KEEP], 
[HCC_DROP], 
[HCC_KEEP_NUMBER] , 
[HCC_DROP_NUMBER]  
)
	select 
	b.[Part_C_D_Flag],
	a.RAFactorType ,
	b.[Payment_Year]  ,
	[ModelVersion] = a.[ModelVersion],
	b.[HCC_KEEP],
	b.[HCC_DROP],
	b.[HCC_KEEP_NUMBER] ,
	b.[HCC_DROP_NUMBER]  
	from ProdSupport.dbo.[lk_Risk_Score_Factors_Master] a inner join
	HRPReporting.dbo.lk_Risk_Models_Hierarchy b
	on a.PaymentYear = b.Payment_Year 
	AND a.RAFactorType = b.RA_FACTOR_TYPE
	where  b.Payment_Year in ( 2020)
	--and a.RAFactorType in ('CF','CN','CP','I','E','SE','D','ED','C1','C2','I1','I2','E1','E2','G1','G2','D1','D2','D3')
	Group by 	b.[Part_C_D_Flag],
	a.RAFactorType ,
	b.[Payment_Year]  ,
	 a.[ModelVersion],
	b.[HCC_KEEP],
	b.[HCC_DROP],
	b.[HCC_KEEP_NUMBER] ,
	b.[HCC_DROP_NUMBER]
	order by a.RAFactorType


	select top 10 * from [#lkRiskModelsHierarchy]
	select top 10 * from HRPReporting.dbo.lk_Risk_Models_Hierarchy where Payment_Year = 2020


	select count(1) from [#lkRiskModelsHierarchy]
	select count(1) from HRPReporting.dbo.lk_Risk_Models_Hierarchy where Payment_Year = 2020

	select RA_FACTOR_TYPE, modelversion, count(1) from [#lkRiskModelsHierarchy] group by RA_FACTOR_TYPE, modelversion order by RA_FACTOR_TYPE, modelversion
	select RA_FACTOR_TYPE, count(1) from HRPReporting.dbo.lk_Risk_Models_Hierarchy where Payment_Year = 2020 group by RA_FACTOR_TYPE order by RA_FACTOR_TYPE

	

	select Part_C_D_Flag, RA_FACTOR_TYPE, Payment_Year, HCC_KEEP, HCC_DROP, HCC_KEEP_NUMBER, HCC_DROP_NUMBER from [#lkRiskModelsHierarchy]
	except
	select Part_C_D_Flag, RA_FACTOR_TYPE, Payment_Year, HCC_KEEP, HCC_DROP, HCC_KEEP_NUMBER, HCC_DROP_NUMBER from HRPReporting.dbo.lk_Risk_Models_Hierarchy where Payment_Year = 2020

	select Part_C_D_Flag, RA_FACTOR_TYPE, Payment_Year, HCC_KEEP, HCC_DROP, HCC_KEEP_NUMBER, HCC_DROP_NUMBER from HRPReporting.dbo.lk_Risk_Models_Hierarchy where Payment_Year = 2020
	except
	select Part_C_D_Flag, RA_FACTOR_TYPE, Payment_Year, HCC_KEEP, HCC_DROP, HCC_KEEP_NUMBER, HCC_DROP_NUMBER from [#lkRiskModelsHierarchy]

	