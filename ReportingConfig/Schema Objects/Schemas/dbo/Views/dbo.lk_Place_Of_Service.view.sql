CREATE VIEW [dbo].[lk_Place_Of_Service] AS
SELECT
	[POS_ID],
	[POS_CODE],
	[POS_NAME],
	[DESCRIPTION],
	[EFFECTIVE_DATE],
	[TERMINATION_DATE]
FROM [$(HRPReporting)].[dbo].[lk_Place_Of_Service]