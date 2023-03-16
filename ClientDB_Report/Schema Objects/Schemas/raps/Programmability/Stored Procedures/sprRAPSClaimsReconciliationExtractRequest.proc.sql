-- ======================================================================================================================
-- Modified By:		Josh Irwin
-- Modified Date:	1/16/2019
-- Description:		The purpose of this stored proc is to extract data related to RAPS Claims Reconciliation details.
--					When the user clicks on the Original/Split File Name this extract will run and deliver the file to 
--					their lite folder.
-- TFS Ticket:		74723
-- =======================================================================================================================
-- Modified By:		Sushil Bhattarai
-- Modified Date:	08/30/2019
-- Description:		Modified proc to use LOB
-- TFS Ticket:		76735
-- =======================================================================================================================
-- Modified By:		Josh Irwin
-- Modified Date:	10/2/2019
-- Description:		Added @GENERALSTARTDATE, @GENERALENDDATE, @ExtractAllFiles to support Extract All functionality
-- TFS Ticket:		76872
-- =======================================================================================================================
CREATE PROCEDURE raps.sprRAPSClaimsReconciliationExtractRequest
	@ClaimSource VARCHAR(8000)
	,@ReportLevel VARCHAR(20)
	,@FileName VARCHAR(255)
	,@UserID INT
	,@LOB VARCHAR(100)
	,@GENERALSTARTDATE DATETIME
	,@GENERALENDDATE DATETIME
	,@ExtractAllFiles BIT

AS
BEGIN
	SET NOCOUNT ON;
	
	--DECLARE
	--	@ClaimSource VARCHAR(8000) = 'All Claim Sources'
	--	,@ReportLevel VARCHAR(20) = 'Original'
	--	,@FileName VARCHAR(255) = 'CLAIMS_H1610_201811281449.txt'
	--	,@UserID INT = 1
	--	,@LOB VARCHAR(100) = 'All Line of Businesses'
	--	,@GENERALSTARTDATE = '1/1/2019'
	--	,@GENERALENDDATE = '1/31/2019'
	--	,@ExtractAllFiles = 0

	-- Create/drop temp tables needed for extract request
	IF OBJECT_ID('[tempdb].[dbo].[#Parameters]', 'U') IS NOT NULL
		DROP TABLE #Parameters

	CREATE TABLE #Parameters (
		ParameterName VARCHAR(500),
		ParameterValue VARCHAR(MAX)
		)

	IF OBJECT_ID('[tempdb].[dbo].[#RequestMessage]', 'U') IS NOT NULL
		DROP TABLE #RequestMessage

	CREATE TABLE #RequestMessage (
		RequestMessage VARCHAR(300)
		)

		-- Declare and set variables
		DECLARE	@AppCode VARCHAR(10) = 'RE'
		DECLARE @DBName VARCHAR(80) = (SELECT DB_NAME() AS DatabaseName)
		DECLARE @OrganizationID INT
		DECLARE @XMLPath XML
		DECLARE @ExtractRequestID BIGINT
		
		SELECT @OrganizationID = 
			(
				SELECT
					OrganizationID
				FROM RptOpsMetrics.mra.RequestQueueStatus WITH(NOLOCK)
				WHERE 
						ReportDatabaseName = @DBName
					AND 
						Category = 'RiskAdjustment' 
			)

		-- Update RequestQueueStatus to set queue to active
		UPDATE rqs
		SET
			rqs.Active = 1,
			rqs.UserID = SUSER_NAME(),
			rqs.LoadDate = GETDATE()
		FROM RptOpsMetrics.mra.RequestQueueStatus rqs
		WHERE 
				rqs.OrganizationID = @OrganizationID
			AND 
				rqs.ApplicationCode = @AppCode
			AND 
				rqs.Category = 'RiskAdjustment'
			AND 
				rqs.ReportDatabaseName = @DBName
			AND 
				rqs.Active = 0

		-- Declare and set @ExtractID 
		DECLARE @ExtractID BIGINT = 
			(
				SELECT
					e.ExtractID
				FROM dbo.[Extract] e WITH (NOLOCK) 
				WHERE 
						e.ActiveFlag = 1
					AND 
						e.ExtractName = 'RAPSReconciliationClaimsDetailExtract' 
			)

		INSERT INTO #Parameters 
			(
				 ParameterName
				,ParameterValue
			)
			(
					SELECT 'ClaimSource' AS ParameterName, @ClaimSource AS ParameterValue
				UNION ALL
					SELECT 'ReportLevel' AS ParameterName, @ReportLevel AS ParameterValue
				UNION ALL
					SELECT 'FileName' AS ParameterName, @FileName AS ParameterValue
				UNION ALL
					SELECT 'UserID' AS ParameterName, CAST(@UserID AS VARCHAR(20)) AS ParameterValue
				UNION ALL
					SELECT 'LOB' AS ParameterName, @LOB AS ParameterValue
				UNION ALL
					SELECT 'GENERALSTARTDATE' AS ParameterName, CAST(@GENERALSTARTDATE AS VARCHAR(20)) AS ParameterValue
				UNION ALL
					SELECT 'GENERALENDDATE' AS ParameterName, CAST(@GENERALENDDATE AS VARCHAR(20)) AS ParameterValue
				UNION ALL
					SELECT 'ExtractAllFiles' AS ParameterName, CAST(@ExtractAllFiles AS CHAR(1)) AS ParameterValue
			)

		SELECT @XMLPath = 
			(	
				SELECT
					ParameterName,
					ParameterValue
				FROM #Parameters
				FOR XML PATH('Parameters'), ROOT ('ReportParameters') 
			);
		
		-- Call SP to load dbo.ExtractRequest
		EXEC dbo.ExtractRequestLoad
			 @OrganizationID
			,@UserID
			,@Appcode
			,@ExtractID
			,@ExtractRequestID OUTPUT
			,@XMLPath

		INSERT INTO #RequestMessage (
			RequestMessage 
			)
		SELECT 'Your request for extract is being generated. Once the extract is complete, the file will be placed in your lite folder. Your extract request number is : ' + CONVERT(VARCHAR(300), @ExtractRequestID) AS 'RequestMessage'		

		SELECT 
			RequestMessage
		FROM #RequestMessage

END