CREATE PROCEDURE [Valuation].[ConfigGetFilteredAuditDetailWrapper]

AS
    SET STATISTICS IO OFF
    SET NOCOUNT ON


/************************************************************************************ 
* Name			:	Valuation.ConfigGetFilteredAuditDetailWrapper							*
* Type 			:	Stored Procedure												*
* Author       	:	D. Waddell													    *
* Date			:	2016-02-03												     	*
* Version		:	1.0																*
* Description	:	proc serves as a control for the process to add				    *
*					the Filtered Audit Control to ConfigGetFilteredAuditDetail		*
*																					*
* Version History	:																*
* ===================																*
* Author			Date		  Version#    TFS Ticket#	Description				*
* -----------------	----------  --------    -----------	------------				*
* DWaddell			2016-02-17  1.0			50383			Initial					*
*																					*
************************************************************************************/ 





DECLARE @AutoProcessRunId_OUT INT
DECLARE @AutoProcessRunId INT
DECLARE @ClientId02 INT
DECLARE @ClientName02 VARCHAR(128)
DECLARE @ClientLevelDb02 VARCHAR(128)
DECLARE @ClientReportDb02 VARCHAR(128)
DECLARE @ClientDescription VARCHAR(256)



SELECT @ClientId02 = [ClientId], @ClientLevelDb02 = [ClientLevelDb], @ClientReportDb02 = [ClientReportDb],@ClientName02 = [ClientName]
FROM [Valuation].[ConfigClientMain] ccm WITH (NOLOCK)
WHERE ccm.[ClientName] = LEFT(DB_NAME(),PATINDEX('%[_]%', DB_NAME()) -1)

SET @ClientDescription = @ClientName02 + ' - Filtered Audit Data Pull'
		

IF ISNULL(@ClientId02,0) = 0
		
			BEGIN
                  RETURN;
					
            END;

/* Get AutoProcessRund ID*/
EXEC [dbo].[AutoGetProcessRunId] @ClientId02,-1,@ClientDescription, @AutoProcessRunId output

SET @AutoProcessRunId_OUT =  @AutoProcessRunId 

/* Insert AutoProcessRun ID info into ConfigGetFileteredAudit Detail table */
EXEC [Valuation].[ConfigGetFilteredAuditDetail] 
	@ClientId02 
	,@AutoProcessRunId_OUT
	,@ClientLevelDb02 
	,@ClientReportDb02 
	,0

RETURN 
