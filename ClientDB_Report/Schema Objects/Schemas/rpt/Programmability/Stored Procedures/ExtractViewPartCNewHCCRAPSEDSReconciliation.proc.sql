/*******************************************************************************************************************************
* Name			:	rpt.ExtractViewPartCNewHCCRAPSEDSReconciliation
* Type 			:	Stored Procedure          
* Author       	:	Rakshit Lall
* TFS#          :   73973
* Date          :	11/2/2018
* Version		:	1.0
* Project		:	SP for generating the output of PartCNewHCCRAPSEDSReconciliation table - Extract Files
* SP call		:	rpt.ExtractViewPartCNewHCCRAPSEDSReconciliation 2018, 'H1099', 'InBothRAPSAndEDS, InRAPSButNotInEDS, InEDSButNotInRAPS', 0
* Version History :
  Author			Date		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------ 
*********************************************************************************************************************************/

CREATE PROCEDURE rpt.ExtractViewPartCNewHCCRAPSEDSReconciliation
	@PaymentYear INT,
	@PlanID VARCHAR(200),
	@HCCStatus VARCHAR(150),
	@UserID BIGINT,
	@ViewThrough INT
AS
BEGIN

SET NOCOUNT ON;

/* Drop temp tables needed for extract request */

IF OBJECT_ID('TempDb..#Parameters') IS NOT NULL 
DROP TABLE #Parameters

IF OBJECT_ID('TempDb..#RequestMessage') IS NOT NULL 
DROP TABLE #RequestMessage

IF (@ViewThrough = 0)
BEGIN

	DECLARE	@AppCode VARCHAR(10) = 'RE'

	DECLARE @DBName VARCHAR(80) = (SELECT DB_NAME() AS DatabaseName)

	DECLARE @OrganizationID INT

	SELECT @OrganizationID =
			(
				SELECT OrganizationID
				FROM RptOpsMetrics.mra.RequestQueueStatus WITH(NOLOCK)
				WHERE ReportDatabaseName = @DBName
				AND Category = 'RiskAdjustment'
			)

	UPDATE RQS
	SET
		RQS.Active = 1,
		RQS.UserID = SUSER_NAME(),
		RQS.LoadDate = GETDATE()
	FROM RptOpsMetrics.mra.RequestQueueStatus RQS
	WHERE
		RQS.OrganizationID = @OrganizationID
	AND
		RQS.ApplicationCode = @AppCode
	AND
		RQS.Category = 'RiskAdjustment'
	AND
		RQS.ReportDatabaseName = @DBName
	AND
		RQS.Active = 0

	CREATE TABLE #Parameters
	(
		ParameterName VARCHAR(1000),
		ParameterValue VARCHAR(MAX) 
	)	

	CREATE TABLE #RequestMessage
	(
		RequestMessage VARCHAR(300)
	)

	/* Converting the local Variables internally so the Extract request will run and variables can be inserted into #Parameters */
	
	DECLARE
		@PYear VARCHAR(4) = @PaymentYear,
		@PID VARCHAR(200) = @PlanID,
		@Status VARCHAR(150) = @HCCStatus,		
		@UID VARCHAR(50) = @UserID,
		-- For inserting in to dbo.ExtractRequestParameter
		@XMLPath XML,
		@ExtractRequestID BIGINT

	DECLARE @ExtractID BIGINT = 
		(
			SELECT E.ExtractID
			FROM dbo.Extract E WITH(NOLOCK) 
			WHERE 
				E.ActiveFlag = 1
			AND
				E.ExtractName = 'PartCNewHCCRAPSEDSReconciliationExtract'
		)
		
	INSERT INTO #Parameters
	(
		ParameterName,
		ParameterValue
	)
	(
		SELECT
			'PaymentYear' AS ParameterName, @PYear AS ParameterValue
		UNION ALL
		SELECT
			'PlanID' AS ParameterName, @PID AS ParameterValue
		UNION ALL
		SELECT
			'HCCStatus' AS ParameterName, @Status AS ParameterValue	
		UNION ALL
		SELECT
			'UserID' AS ParameterName, @UID AS ParameterValue
	)
	SELECT @XMLPath =
	(	
		SELECT
			ParameterName,
			ParameterValue
		FROM #Parameters
		FOR XML PATH('Parameters'), ROOT ('ReportParameters')
	);
		
	/* Calling SP to load dbo.ExtractRequest and dbo.ExtractRequestParameter */

	EXEC [dbo].[ExtractRequestLoad] @OrganizationID, @UID, @Appcode, @ExtractID, @ExtractRequestID OUTPUT, @XMLPath

	INSERT INTO #RequestMessage
	(
		RequestMessage
	)
	SELECT 'Your request for extract is being generated. Once the extract is complete, the file will be placed in your lite folder. Your extract request number is : '  + CONVERT(VARCHAR(300), @ExtractRequestID) AS 'RequestMessage'

	SELECT RequestMessage
	FROM #RequestMessage

END

END