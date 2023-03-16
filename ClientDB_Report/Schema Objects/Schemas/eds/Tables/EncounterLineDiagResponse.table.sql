CREATE TABLE [eds].[EncounterLineDiagResponse](
	[EncounterLineDiagResponseID] [int] IDENTITY(1,1) NOT NULL,
	[PlanClaimID] [varchar](50) NOT NULL,
	[ClaimLineNumber] [varchar](50) NOT NULL,
	[LineDiag1] [varchar](20) NULL,
	[LineDiag2] [varchar](20) NULL,
	[LineDiag3] [varchar](20) NULL,
	[LineDiag4] [varchar](20) NULL,
	[EncounterRapsRollupStatusID] [tinyint] NOT NULL,
	[CreatedDateTime] [datetime2](7) NOT NULL,
	[LoadID] [bigint] NOT NULL,
	[LoadDate] [datetime] NOT NULL)