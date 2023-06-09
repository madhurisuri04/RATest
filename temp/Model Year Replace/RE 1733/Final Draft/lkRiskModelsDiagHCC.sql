CREATE TABLE [dbo].[lkRiskModelsDiagHCC]
(
	[lkRiskModelsDiagHCCID] [int] IDENTITY(1,1) NOT NULL,
	[ICD10CD] [varchar](10) NOT NULL,
	[HCCLabel] [varchar](10) NOT NULL,
	[PaymentYear] [int] NOT NULL,
	[ModelVersion] [smallint] NULL,
	[HCCNumber] [varchar](4) NOT NULL,
	[RAFactorType] [varchar](3) NOT NULL,
	[HCCIsChronic] [varchar](2) NOT NULL,
	[LoadID] [bigint] NOT NULL,
	[LoadDate] [datetime] NOT NULL
)

 