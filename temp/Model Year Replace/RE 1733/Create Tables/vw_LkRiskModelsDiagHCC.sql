use HRPReporting

CREATE VIEW [dbo].[vwLkRiskModelsDiagHCC]
AS
	SELECT CONVERT(TINYINT, 9) AS ICDClassification
	,      [ICD9] AS ICDCode
	,      [HCC_Label] AS HCCLabel
	,      [Payment_Year] AS PaymentYear
	,      [HCC_Number] AS HCCNumber
	,      [Factor_Type] AS FactorType
	,      [HCCIsChronic] AS HCCIsChronic
	,      NULL AS VERSION
	FROM dbo.lk_Risk_Models_DiagHCC

	UNION ALL

	SELECT CONVERT(TINYINT, 10) AS ICDClassification
	,      [ICD10CD] AS ICDCode
	,      [HCCLabel] AS HCCLabel
	,      [PaymentYear] AS PaymentYear
	,      [HCCNumber]  AS HCCNumber
	,      [FactorType] AS FactorType
	,      [HCCIsChronic] AS HCCIsChronic
	,      [ModelVersion] AS Version
	FROM dbo.lkRiskModelsDiagHCC
