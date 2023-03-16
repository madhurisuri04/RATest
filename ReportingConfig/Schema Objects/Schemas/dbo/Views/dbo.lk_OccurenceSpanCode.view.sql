CREATE VIEW [dbo].[lk_OccurenceSpanCode] AS
SELECT
	OccurenceSpanCodeID,
    [Code],
    [Description],
    [EffectiveDate],
    [TerminationDate]
FROM [$(HRPReporting)].[dbo].[lk_OccurenceSpanCode]