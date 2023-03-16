﻿CREATE PROCEDURE [dbo].[spr_GetUserPassword]
	@Email varchar(200)
 AS


SET NOCOUNT ON

IF EXISTS(SELECT * FROM tbl_Users WHERE EMAIL = @Email AND ACTIVE = 1)
BEGIN
	SELECT [PASSWORD] FROM tbl_Users WHERE EMAIL = @Email

	UPDATE TBL_USERS SET Force_Password_Change = 1 WHERE EMAIL = @Email
END
ELSE
BEGIN
	SELECT '' AS [PASSWORD] 
END
	

SET NOCOUNT OFF