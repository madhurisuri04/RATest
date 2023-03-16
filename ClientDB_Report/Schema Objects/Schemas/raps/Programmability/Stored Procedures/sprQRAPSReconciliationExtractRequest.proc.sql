-- ======================================================================================================================
-- Modified By:		Josh Irwin
-- Modified Date:	10/19/2019
-- Description:		The purpose of this stored proc is to extract data related to QRAPS Reconciliation details. When the
--					user clicks on the Original/Split File Name or 'Extract All Files Displayed' this extract will run and
--					deliver the file to their lite folder.
-- TFS Ticket:		77017
-- =======================================================================================================================
-- Modified By:		Josh Irwin
-- Modified Date:	4/1/2020
-- Description:		Added FileType parameter to stored procedure
-- TFS Ticket:		78178
-- =======================================================================================================================
CREATE PROCEDURE raps.sprQRAPSReconciliationExtractRequest
	@ReportLevel VARCHAR(20)
	,@FileName VARCHAR(255)
	,@PlanID VARCHAR(8000)
	,@LOB VARCHAR(100)
	,@GENERALSTARTDATE DATETIME
	,@GENERALENDDATE DATETIME
	,@ExtractAllFiles BIT
	,@FileType VARCHAR(20)
	,@UserID INT

AS
BEGIN
	SET NOCOUNT ON;
	
	--DECLARE
	--	@ReportLevel VARCHAR(20) = 'Original'
	--	,@FileName VARCHAR(255) = 'CLAIMS_H1610_201811281449.txt'
	--	,@PlanID VARCHAR(8000) = 'All Plan IDs'
	--	,@LOB VARCHAR(100) = 'All Line of Businesses'
	--	,@GENERALSTARTDATE DATETIME = '1/1/2019'
	--	,@GENERALENDDATE DATETIME = '1/31/2019'
	--	,@ExtractAllFiles BIT = 0
	--	,@FileType = 'UI'
	--	,@UserID INT = 1

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
						e.ExtractName = 'QRAPSReconciliationDetailExtract' 
			)

		INSERT INTO #Parameters 
			(
				 ParameterName
				,ParameterValue
			)
			(
					SELECT 'ReportLevel' AS ParameterName, @ReportLevel AS ParameterValue
				UNION ALL
					SELECT 'FileName' AS ParameterName, @FileName AS ParameterValue
				UNION ALL
					SELECT 'PlanID' AS ParameterName, @PlanID AS ParameterValue
				UNION ALL
					SELECT 'LOB' AS ParameterName, @LOB AS ParameterValue
				UNION ALL
					SELECT 'GENERALSTARTDATE' AS ParameterName, CAST(@GENERALSTARTDATE AS VARCHAR(20)) AS ParameterValue
				UNION ALL
					SELECT 'GENERALENDDATE' AS ParameterName, CAST(@GENERALENDDATE AS VARCHAR(20)) AS ParameterValue
				UNION ALL
					SELECT 'ExtractAllFiles' AS ParameterName, CAST(@ExtractAllFiles AS CHAR(1)) AS ParameterValue
				UNION ALL
					SELECT 'FileType' AS ParameterName, CAST(@FileType AS VARCHAR(20)) AS ParameterValue
				UNION ALL
					SELECT 'UserID' AS ParameterName, CAST(@UserID AS VARCHAR(20)) AS ParameterValue
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