CREATE TABLE [eds].[EncounterRapsRollupDiagnosis](
	[EncounterRapsRollupDiagnosisID] [int] IDENTITY(1,1) NOT NULL,
	[EncounterRapsRollupID] [int] NOT NULL,
	[Diagnosis] [varchar](20) NOT NULL,
	[Ordinal] [smallint] NOT NULL,
	[LoadID] [bigint] NOT NULL,
	[LoadDate] [datetime] NOT NULL)