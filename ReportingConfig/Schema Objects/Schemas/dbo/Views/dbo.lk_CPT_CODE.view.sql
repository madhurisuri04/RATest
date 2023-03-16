CREATE VIEW [dbo].[lk_CPT_CODE] AS
SELECT
    [CPTID],
    [CPT],
    [Modifier],
    [Short_Description],
    [Medium_Description],
    [Long_Description],
    [Work_RVU],
    [FPE_RVU],
    [NPE_RVU],
    [PLI_RVU],
    [TotFac_RVU],
    [TotNonfac_RVU],
    [Medicare_Global_Period],
    [StartDate],
    [EndDate]
FROM [$(HRPReporting)].[dbo].[lk_CPT_CODE]