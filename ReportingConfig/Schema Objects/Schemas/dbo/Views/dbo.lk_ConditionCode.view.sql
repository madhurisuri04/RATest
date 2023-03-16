CREATE VIEW [dbo].[lk_ConditionCode] AS
SELECT
	ConditionCodeID,
    [Code],
    [Description],
    [EffectiveDate],
    [TerminationDate]
FROM [$(HRPReporting)].[dbo].[lk_ConditionCode]