﻿CREATE PROCEDURE [dbo].[spr_GetUserConnections]
	@userid int,
	@ip varchar(20) = ''
 AS


SET NOCOUNT ON;

DECLARE @TASKID INT
DECLARE @CONNECTIONNAME VARCHAR(100)

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

SELECT @TASKID = TASK_ID FROM lk_UserTasks WHERE TASK_DESCRIPTION = 'Connection'

IF (SELECT Admin_User FROM tbl_Users WHERE User_ID = @userid) = 1
BEGIN
	SELECT Connection_Display_Name, Connection_Name, Connection_ID, Plan_ID FROM tbl_Connection ORDER BY Connection_Display_Name
	--IF THE USER IS AN ADMIN AND ONLY ONE CONNECTION EXISTS THEN WE WANT TO LOG IT
	IF (SELECT COUNT(*) FROM tbl_Connection) = 1
	BEGIN
		SET @CONNECTIONNAME = (SELECT TOP 1 CONNECTION_NAME FROM TBL_CONNECTION)
		INSERT INTO xref_User_Task_History (USER_ID, TASK_ID, ACTION_TEXT, DATE_LOGGED)
		VALUES(@userid, @taskid, @CONNECTIONNAME, GETDATE())
	END
END
ELSE
BEGIN
	
	--CHECK TO SEE IF THIS IS AN HRP FLAGGED USER IF IT IS DON'T DO THE IP CHECK
	IF (SELECT EXCLUDE_FROM_LOG_REPORT FROM TBL_USERS WHERE [User_ID] = @userid) = 1
	BEGIN
		SELECT C.Connection_Display_Name, C.Connection_Name, C.Connection_ID, C.Plan_ID From tbl_Connection C 
		INNER JOIN xref_User_Connections XC 
		ON XC.Connection_ID = C.Connection_ID
		WHERE XC.User_ID = @userid 
		ORDER BY C.Connection_Display_Name
	END
	ELSE
	BEGIN
		SELECT C.Connection_Display_Name, C.Connection_Name, C.Connection_ID, C.Plan_ID From tbl_Connection C 
		INNER JOIN xref_User_Connections XC 
		ON XC.Connection_ID = C.Connection_ID
		WHERE XC.User_ID = @userid 
		AND C.CONNECTION_ID IN (SELECT CONNECTION_ID FROM #TEMPCONNECTION)
		ORDER BY C.Connection_Display_Name
	END
	

	--IF THE USER ONLY HAS ONE CONNECTION THEN LOG THAT THEY CONNECTED TO IT IN THE HISTORY TABLE
	--IF THEY HAVE MORE THAN ONE CONNECTION THEN IT WILL BE CAPTURED ELSEWHERE WHEN THEY SELECT IT
	--IN THE WEB APPLICATION
	IF (SELECT COUNT(*) FROM xref_User_Connections WHERE User_ID = @userid) = 1
	BEGIN
		SET @CONNECTIONNAME = (SELECT TOP 1 CONNECTION_NAME FROM TBL_CONNECTION WHERE CONNECTION_ID = (SELECT CONNECTION_ID FROM xref_User_Connections WHERE User_ID = @userid))
		INSERT INTO xref_User_Task_History (USER_ID, TASK_ID, ACTION_TEXT, DATE_LOGGED)
		VALUES(@userid, @taskid, @CONNECTIONNAME, GETDATE())
	END

END

DROP TABLE #TEMPCONNECTION


SET NOCOUNT OFF