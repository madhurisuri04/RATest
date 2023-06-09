Create PROCEDURE [dbo].[spr_JobWait]

@ClientID int, 
@RunGroup Varchar(MAX)

/********************************************************************************************************************** 
  * Name			:	[dbo].[spr_JobWait]																				*
  * Type 			:	Stored Procedure																				*
  * Author       	:	Anand
  * Date			:	2019-12-13																						*
  * Version			:	1.0																								*
  * Description		:	This stored procedure will check and wait for the completion of Run Group - jobs listed in the				* 
  *						@RunGroup parameter.																		*
  *																														*
  * Version History :																									*
  * =================																									*
  * Author			Date			Version#    TFS Ticket#		Description												*
  * ---------------	----------		--------    -----------		------------											*
  * Anand			2019-12-13		1.0							Initial													*
  *	Anand			2020-01-07		1.1			RE-7431/77587	Added ClientID																												*
**********************************************************************************************************************/

AS

SET NOCOUNT ON
 
IF OBJECT_ID('[tempdb].[dbo].[#RunGroup]', 'U') IS NOT NULL DROP TABLE #RunGroup
CREATE TABLE #RunGroup
(
RunGroup Char(2)
)

BEGIN 
		INSERT INTO #RunGroup
		Select Item from dbo.fnsplit(@RunGroup,',')
END

WHILE 1 = 1
BEGIN

    IF NOT EXISTS
    (
        SELECT *
        FROM RollupRunGroupLog R with(Nolock) Inner join #RunGroup RG
		on [R].[RunGroup]=[RG].[RunGroup]
        WHERE [R].[End_Time] is null
		and [R].[ClientIdentifier]=@ClientID
    )
    BEGIN
        RAISERROR('Breaking now', 0, 1) WITH NOWAIT
        BREAK
    END

    WAITFOR DELAY '00:01:00'


END
 