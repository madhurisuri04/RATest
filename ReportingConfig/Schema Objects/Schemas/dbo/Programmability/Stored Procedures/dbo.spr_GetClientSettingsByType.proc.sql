-- =============================================
-- Author:		Wallace Middleton, Jr.
-- Create date: Feb 28, 2011
-- =============================================
CREATE PROCEDURE [dbo].[spr_GetClientSettingsByType]
	@Client_ID INT,
	@SettingType VARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT ClientSettingValueID, ISNULL(SettingValue,DefaultSettingValue) AS SettingValue
	FROM dbo.tbl_ClientSettingTypes t1
	LEFT JOIN dbo.tbl_ClientSettingValues t2 
		ON t1.ClientSettingTypeID = t2.ClientSettingTypeID
		AND t2.Client_ID = @Client_ID
	WHERE t1.SettingType = @SettingType
		AND (DefaultSettingValue IS NOT NULL OR  SettingValue IS NOT NULL)

END