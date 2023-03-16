/****************************************************************************************************************                    
* Author       	: Rakshit Lall
* TFS			:	
* Date          : 08/24/2017
* Description	:	
* For Test		: EXEC [rpt].[ExtractViewEstimatedReceivableDetail] '2016', 'N', 'H3204', 'C', 4200, 0
	
* Version History :
  Author			Date		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------  
*****************************************************************************************************************/   
CREATE PROCEDURE [rpt].[ExtractViewEstimatedReceivableDetail] 
(
	 @PaymentYear VARCHAR(4)
	,@MYUFlag CHAR(1)
	,@Plan VARCHAR(1000)
	,@RAFactorType VARCHAR(100)
	,@UserID BIGINT
	,@ViewThrough INT
)

WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;

SET FMTONLY OFF;

-- Drop temp tables needed for extract request

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
		ParameterName VARCHAR(500),
		ParameterValue VARCHAR(MAX) 
	)	

	CREATE TABLE #RequestMessage
	(
		RequestMessage VARCHAR(300)
	)
--Converting the local Variables internally so the Extract request will run and variables can be inserted into #Parameters
	DECLARE
		@PYear VARCHAR(4) = @PaymentYear,
		@MYU CHAR(1) = @MYUFlag,
		@Pln VARCHAR(1000) = @Plan,
		@RAFT VARCHAR(100) = @RAFactorType,
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
				E.ExtractName = 'EstimatedReceivableExtract'
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
			'MYU' AS ParameterName, @MYU AS ParameterValue
		UNION ALL
		SELECT
			'Plan' AS ParameterName, @Plan AS ParameterValue
		UNION ALL
		SELECT
			'RAFactorType' AS ParameterName, @RAFT AS ParameterValue	
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
		
	-- Calling SP to load dbo.ExtractRequest and dbo.ExtractRequestParameter

	EXEC [dbo].[ExtractRequestLoad] @OrganizationID, @UID, @Appcode, @ExtractID, @ExtractRequestID OUTPUT, @XMLPath

	INSERT INTO #RequestMessage
	(
		RequestMessage
	)
	SELECT 'Your request for extract is being generated. Once the extract is complete, the file will be placed in your lite folder. Your extract request number is : ' + CONVERT(VARCHAR(300), @ExtractRequestID) AS 'RequestMessage'

	SELECT RequestMessage
	FROM #RequestMessage

END

END