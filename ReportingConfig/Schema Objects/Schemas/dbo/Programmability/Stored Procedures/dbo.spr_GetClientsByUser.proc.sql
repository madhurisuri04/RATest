CREATE PROCEDURE [dbo].[spr_GetClientsByUser]
	@userid int,
	@ip varchar(20) = ''
 AS

SET NOCOUNT ON;

CREATE TABLE #TEMPCONNECTION (CONNECTION_ID INT)

IF LEN(@ip) > 0 
BEGIN
	INSERT #TEMPCONNECTION
	EXEC spr_GetConnectionBySourceIP @IP, 1
END
ELSE
BEGIN
	INSERT #TEMPCONNECTION
	SELECT DISTINCT Connection_ID FROM xref_User_Connections WHERE [User_ID] = @userid
END
	
--CHECK TO SEE IF THIS IS AN HRP FLAGGED USER IF IT IS DON'T DO THE IP CHECK
IF (SELECT EXCLUDE_FROM_LOG_REPORT FROM TBL_USERS WHERE [User_ID] = @userid) = 1
BEGIN
	SELECT DISTINCT 
		CL.Client_ID
		, Client_Name
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
	INNER JOIN xref_User_Connections XC 
		ON XC.Connection_ID = C.Connection_ID
	WHERE XC.User_ID = @userid 
END
ELSE
BEGIN
	SELECT DISTINCT 
		CL.Client_ID
		, Client_Name
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
	INNER JOIN xref_User_Connections XC 
	ON XC.Connection_ID = C.Connection_ID
	WHERE XC.User_ID = @userid 
	AND C.CONNECTION_ID IN (SELECT CONNECTION_ID FROM #TEMPCONNECTION)
END

DROP TABLE #TEMPCONNECTION


SET NOCOUNT OFF