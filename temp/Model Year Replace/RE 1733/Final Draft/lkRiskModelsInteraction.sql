CREATE TABLE [dbo].[lkRiskModelsInteraction]
(
	[lkRiskModelsInteractionID] [int] IDENTITY(1,1) NOT NULL,
	[PaymentYear] [int] NOT NULL,
	[ModelVersion] [smallint] NULL,
	[InteractionLabel] [varchar](10) NOT NULL,
	[HCCLabel1] [varchar](50) NOT NULL,
	[HCCLabel2] [varchar](50) NOT NULL,
	[HCCLabel3] [varchar](50) NOT NULL,
	[HCCNumber1] [varchar](50) NOT NULL,
	[HCCNumber2] [varchar](50) NOT NULL,
	[HCCNumber3] [varchar](50) NOT NULL,
	[RAFactorType] [varchar](10) NOT NULL,
	[LongDescription] [varchar](255) NOT NULL,
	[ShortDescription] [varchar](255) NOT NULL, 
    [LoadID] [bigint] NOT NULL,
	[LoadDate] [datetime] NOT NULL
)
 