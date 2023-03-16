/***********************************************************************************************************
 Modified By:		Josh Irwin
 Modified Date:		10/4/2018
 Description:		The purpose of this stored procedure is to return data to the RAPS Claims Reconciliation
					Summary SSRS report.
 TFS Ticket:		73563
***********************************************************************************************************
 Modified By:		Sushil Bhattarai
 Modified Date:		08/30/2019
 Description:		Modified proc to use LOB
 TFS Ticket:		76735
 ***********************************************************************************************************/
CREATE PROCEDURE [raps].[sprRAPSClaimsReconciliationSummary]
	 @GENERALSTARTDATE DATETIME
	,@GENERALENDDATE DATETIME
	,@ClaimSource VARCHAR(8000)
	,@LOB VARCHAR(100)

AS
BEGIN

	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;
	
	--DECLARE @GENERALSTARTDATE DATETIME = '01/01/2017'
	--DECLARE @GENERALENDDATE DATETIME = '12/31/2018'
	--DECLARE @ClaimSource VARCHAR(8000) = 'All Claim Sources'
	--DECLARE @LOB VARCHAR(100) = 'All Line of Businesses'

	DECLARE @tblClaimSource TABLE (Item VARCHAR(100))
	
	INSERT INTO @tblClaimSource (Item)
	SELECT Item
	FROM dbo.fnSplit(@ClaimSource, '|')
	
	DECLARE @tblLOB TABLE (value VARCHAR(100))

	INSERT INTO @tblLOB (value)
	SELECT Item
	FROM dbo.fnSplit(@LOB, '|')

	SELECT
		 MAX(RCRS.RowsReceivedCount) AS RowsReceivedCount
		,MAX(RCRS.DuplicateRowsCount) AS DuplicateRowsCount
		,SUM(RCRS.LoadedCount) AS LoadedCount
		,MAX(RCRS.LineDiag1To10Count) AS LineDiag1To10Count
		,MAX(RCRS.LineDiag11To20Count) AS LineDiag11To20Count
		,MAX(RCRS.LineDiag21To30Count) AS LineDiag21To30Count
		,SUM(RCRS.RiskAdjustableCount) AS RiskAdjustableCount
		,SUM(RCRS.PendingRiskAdjustmentReviewCount) AS PendingRiskAdjustmentReviewCount
		,SUM(RCRS.NonRiskAdjustableCount) AS NonRiskAdjustableCount
		,SUM(RCRS.DuplicateCount) AS DuplicateCount
		,SUM(RCRS.BatchCreatedCount) AS BatchCreatedCount
		,SUM(RCRS.FileCreatedCount) AS FileCreatedCount
		,SUM(RCRS.SubmittedCount) AS SubmittedCount
		,SUM(RCRS.FERASAcceptedCount) AS FERASAcceptedCount
		,SUM(RCRS.FERASRejectedCount) AS FERASRejectedCount
		,SUM(RCRS.RAPSReturnRejectedNonDuplicateCount) AS RAPSReturnRejectedNonDuplicateCount
		,SUM(RCRS.RAPSReturnRejectedDuplicateCount) AS RAPSReturnRejectedDuplicateCount
		,SUM(RCRS.RAPSReturnAcceptedCount) AS RAPSReturnAcceptedCount
		,RCRS.PlanID
		,RCRS.OriginalFileName
		,RCRS.OriginalFileDate AS ReceivedDate
		,RCRS.SplitFileName
	FROM raps.RAPSClaimsReconciliationSummary RCRS WITH (NOLOCK)
	WHERE CAST(RCRS.OriginalFileDate AS DATE) BETWEEN @GENERALSTARTDATE AND @GENERALENDDATE
	AND (
		ISNULL(RCRS.ClaimSource, 'N/A') IN (
			SELECT Item
			FROM @tblClaimSource
		)
		OR @ClaimSource = 'All Claim Sources'
	)
	AND (
		ISNULL(RCRS.LineOfBusiness,'Medicare') IN (
				SELECT VALUE
				FROM @tblLOB )
			OR @LOB = 'All Line of Businesses'
	)
	GROUP BY
		RCRS.PlanID
		,RCRS.OriginalFileName
		,RCRS.OriginalFileDate
		,RCRS.SplitFileName

END