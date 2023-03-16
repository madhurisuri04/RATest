CREATE VIEW [dbo].[xref_User_Connections] AS
SELECT
	[User_ID],
	[Connection_ID],
	[Last_Updated_By],
	[Last_Updated_date]
FROM [$(HRPReporting)].[dbo].[xref_User_Connections]