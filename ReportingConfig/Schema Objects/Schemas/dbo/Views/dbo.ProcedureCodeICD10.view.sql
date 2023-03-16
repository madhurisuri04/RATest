CREATE VIEW [dbo].[ProcedureCodeICD10] AS
SELECT
	[ProcedureCodeICD10ID],
	[ProcedureCD],
	[ProcedureShortDescription],
	[ProcedureLongDescription],
	[EffectiveDate],
	[TerminationDate],
	[Flags],
	[LoadID],
	[LoadDate]
FROM [$(HRPReporting)].[dbo].[ProcedureCodeICD10]