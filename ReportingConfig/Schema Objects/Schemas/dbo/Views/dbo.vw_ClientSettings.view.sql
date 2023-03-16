CREATE VIEW dbo.vw_ClientSettings
AS
SELECT
	dbo.tbl_Clients.Client_ID
	, dbo.tbl_Clients.Client_Name
	, dbo.tbl_ClientSettingTypes.ClientSettingTypeID
	, dbo.tbl_ClientSettingTypes.SettingType
	, dbo.tbl_ClientSettingTypes.Description
	, dbo.tbl_ClientSettingValues.SettingValue
FROM
	dbo.tbl_Clients
	INNER JOIN dbo.tbl_ClientSettingValues 
		ON dbo.tbl_Clients.Client_ID = dbo.tbl_ClientSettingValues.Client_ID
	INNER JOIN dbo.tbl_ClientSettingTypes 
		ON dbo.tbl_ClientSettingTypes.ClientSettingTypeID = dbo.tbl_ClientSettingValues.ClientSettingTypeID
