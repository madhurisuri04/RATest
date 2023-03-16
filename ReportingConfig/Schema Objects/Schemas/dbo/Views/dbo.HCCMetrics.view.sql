CREATE VIEW [dbo].[HCCMetrics] AS
SELECT 
	DHCC.ICD9
	, DHCC.HCC_Label as HCC
	, FACTOR.Comm as Factor
	, NORM.PartC_Factor as Norm_Factor
	, NORM.CodingIntensity
	, HCode.Avg_MA_Bid as Avg_MA_Bid
	, HCode.Est_Member_Months as Est_Member_Months
	, ROUND((FACTOR.Comm/NORM.PartC_Factor)*(1-NORM.CodingIntensity),3) Normalized_Factor
	, Round(ROUND((FACTOR.Comm/NORM.PartC_Factor)*(1-NORM.CodingIntensity),3)*HCode.Avg_MA_Bid*HCode.Est_Member_Months,2) as Estimated_Value
	, DHCC.Payment_Year as 'year'
	, FACTOR.Payment_Year as 'factoryear'
	, dbo.HCCMostRecentModification(DHCC.ModifiedDate,FACTOR.ModifiedDate,NORM.ModifiedDate,HCode.ModifiedDate,DATEADD(dd,-1,getdate())) as 'ModifiedDate'
FROM 
	(   select * from dbo.lk_DiagnosesHCC_PartC 
		where Payment_Year IN ( 
			YEAR(DATEADD(yy,-2,GETDATE()))		-- 2 years ago
			, YEAR(DATEADD(yy,-1,GETDATE()))	-- last year
			, YEAR(GetDate())					-- this year
			, YEAR(DATEADD(yy,1,GETDATE()))		-- next year
			, YEAR(DATEADD(yy,2,GETDATE()))		-- year after next
		)
	) DHCC
	join dbo.lk_Factors_PartC FACTOR 
		on DHCC.HCC_Label = FACTOR.HCC_Label
		and DHCC.Payment_Year = FACTOR.Payment_Year
	join dbo.lk_normalization_factors NORM         
		on DHCC.Payment_Year = NORM.[Year]
	join (	select					-- EMULATED TABLE FOR HARD-CODED VALUES
				DISTINCT ICD9		-- EDIT VALUES BELOW TO CHANGE HARD CODING, OR POINT TO REAL DATA
				, 750.00 as Avg_MA_Bid
				, 12.00 as Est_Member_Months 
				, ModifiedDate
			from dbo.lk_DiagnosesHCC_PartC
		) HCode
		on DHCC.ICD9 = HCode.ICD9