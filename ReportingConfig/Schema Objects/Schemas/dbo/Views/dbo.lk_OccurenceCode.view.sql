CREATE VIEW [dbo].[lk_OccurenceCode] AS
SELECT
	OccurenceCodeID,
    [Code],
    [Description],
    [EffectiveDate],
    [TerminationDate]
FROM [$(HRPReporting)].[dbo].[lk_OccurenceCode]
