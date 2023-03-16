CREATE VIEW [dbo].[xref_Client_Connections] AS
SELECT
    [Client_ID],
    [Connection_ID]
FROM [$(HRPReporting)].[dbo].[xref_Client_Connections]