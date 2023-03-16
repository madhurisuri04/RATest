CREATE PROCEDURE [dbo].[GetClientsForEDSUser]
	@userid int
AS

SET NOCOUNT ON;

DECLARE @userClients TABLE ( Client_ID INT );
INSERT INTO @userClients SELECT Client_ID FROM xref_User_Clients WHERE [User_ID] = @userid;
	
SELECT DISTINCT 
	CL.Client_ID
	, Client_Name
	, ClientAlphaID
	, FTP_Folder
	, CL.Default_User_ID
	, Run_Import_Pickup
	, Email_Compliance_Officer
	, SharePointRoot
	, SharePointDocumentLibrary
	, Client_DB
	, DB_Server
	, Client_DB_CN
	, Client_DB_CN_Server
	, MergeRAPSsubmissions
	, MergeRAPSOutputFolder
	, MergeRAPSFileNameFormat
	, MergeRAPSFileMaxLines
	, MergeRAPSFileMaxDiagsPerLine
	, ( 
		SELECT SettingValue 
		FROM tbl_ClientSettingValues
		WHERE Client_ID = CL.Client_ID
			AND ClientSettingTypeID IN (
				SELECT ClientSettingTypeID 
				FROM tbl_ClientSettingTypes 
				WHERE SettingType = 'ClientDatabaseName'
			)
		) as EDSDatabase
	, ( 
		SELECT SettingValue 
		FROM tbl_ClientSettingValues
		WHERE Client_ID = CL.Client_ID
			AND ClientSettingTypeID IN (
				SELECT ClientSettingTypeID 
				FROM tbl_ClientSettingTypes 
				WHERE SettingType = 'ClientDatabaseServerName'
			)
		) as EDSServer
FROM tbl_Clients CL
JOIN xref_Client_Connections CC
	ON CC.Client_ID = CL.Client_ID
JOIN tbl_Connection C
	ON C.Connection_ID = CC.Connection_ID
JOIN Organization o on o.OrganizationID = CC.Client_ID	 
WHERE CL.Client_ID IN ( SELECT Client_ID FROM @userClients )

SET NOCOUNT OFF