CREATE VIEW [dbo].[xref_User_Clients] AS
SELECT
	[User_ID],
	[Client_ID],
	[FromRE]
FROM [$(HRPReporting)].[dbo].[xref_User_Clients]