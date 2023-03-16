CREATE PROCEDURE [Valuation].[spr_RptVisibleAutoProcessRun]
	(@ClientId INT)


AS
    SET NOCOUNT ON 
    
/************************************************************************************ 
* Name			:	Valuation.spr_RptVisibleAutoProcessRun							*
* Type 			:	Stored Procedure												*
* Author       	:	D. Waddell													    *
* Date			:	2016-04-04												     	*
* Version		:	1.0																*
* Description	:	This proc selects auto process Run ID for Valuation RDL		    *
*																					*
*																					*
* Version History	:																*
* ===================																*
* Author			Date		  Version#    TFS Ticket#	Description				*
* -----------------	----------  --------    -----------	------------				*
* DWaddell			2016-04-04  1.0			51835			Initial					*
*																					*
************************************************************************************/ 
    
    
    
    
    SELECT
        [ClientId] = [pr].[ClientId]
      , [AutoProcessRunId] = [pr].[AutoProcessRunId]
      , [FriendlyDescription] = [pr].[FriendlyDescription]
    FROM
--        [$(ClientDB_Report)].[Valuation].[AutoProcessRun] pr WITH (NOLOCK)
        [Valuation].[AutoProcessRun] pr WITH (NOLOCK)
        
    WHERE
        [pr].[ClientVisibleBDate] <= GETDATE()
        AND ISNULL([pr].[ClientVisibleEDate], DATEADD(dd, 1, GETDATE())) >= GETDATE()
        AND pr.[ClientId] = @ClientId
ORDER BY [AutoProcessRunId] DESC


RETURN 0