
--IF OBJECT_ID('spr_GetClientSettings','P') IS NOT NULL
--	DROP PROCEDURE [dbo].[spr_GetClientSettings]  
--GO

CREATE PROCEDURE [dbo].[spr_GetClientSettings]
	@SettingType VARCHAR(50),
	@Client_ID INT
AS
BEGIN
	SET NOCOUNT ON;

	SELECT ClientSettingValueID, SettingValue
	FROM dbo.tbl_ClientSettingValues t1
	JOIN dbo.tbl_ClientSettingTypes t2 
		ON t2.ClientSettingTypeID = t1.ClientSettingTypeID
	WHERE t2.SettingType = @SettingType
		AND t1.Client_ID = @Client_ID
END