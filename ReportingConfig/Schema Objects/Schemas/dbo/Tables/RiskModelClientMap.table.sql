CREATE TABLE [dbo].[RiskModelClientMap]
(
	[RiskModelClientMapID] [int] IDENTITY(1,1) NOT NULL,
	[OrganizationID] [int] NOT NULL,
	[RiskModelId] [int] NOT NULL,
	[ModelCode] varchar(50) NOT NULL,
    [CreateDateTime] [datetime2](2)
);