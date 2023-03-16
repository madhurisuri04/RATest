CREATE VIEW [dbo].[LK_ICD9_CODES_REVISED] AS
SELECT
    [ICD9_ID],
    [ICD9CM_CODE],
    [ICD_NO_DEC],
    [CompleteCode],
    [SHORT_DESCRIPTION],
    [LONG_DESCRIPTION],
    [FULL_DESCRIPTION],
    [AutoComplete_Display],
    [StartDate],
    [EndDate]
FROM [$(HRPReporting)].[dbo].[LK_ICD9_CODES_REVISED]