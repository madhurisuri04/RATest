/***********************************************************************************************************
 Modified By:		Josh Irwin
 Modified Date:		8/7/2019
 Description:		The purpose of this stored procedure is to return data to the QRAPS Reconciliation
					Summary SSRS report.
 TFS Ticket:		76587
***********************************************************************************************************
 Modified By:		Josh Irwin
 Modified Date:		2/4/2020
 Description:		Fixed a typo related to 'All Plan IDs'.
 TFS Ticket:		77846
***********************************************************************************************************
 Modified By:		Josh Irwin
 Modified Date:		4/1/2020
 Description:		Added FileType to report results.
 TFS Ticket:		78178
***********************************************************************************************************/
CREATE PROCEDURE [raps].[sprQRAPSReconciliationSummary]
	 @GENERALSTARTDATE DATETIME
	,@GENERALENDDATE DATETIME
	,@LineOfBusiness VARCHAR(50)
	,@PlanID VARCHAR(2000)

AS
BEGIN

	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;
	
	--DECLARE @GENERALSTARTDATE DATETIME = '01/01/2017'
	--DECLARE @GENERALENDDATE DATETIME = '12/31/2018'
	--DECLARE @LineOfBusiness VARCHAR(50) = 'All Line of Businesses'
	--DECLARE @PlanID VARCHAR(2000) = 'All Plan IDs'

	DECLARE @tblLineOfBusiness TABLE (Item VARCHAR(100))
	
	INSERT INTO @tblLineOfBusiness (Item)
	SELECT Item
	FROM dbo.fnSplit(@LineOfBusiness, '|')

	DECLARE @tblPlanID TABLE (Item VARCHAR(100))
	
	INSERT INTO @tblPlanID (Item)
	SELECT Item
	FROM dbo.fnSplit(@PlanID, '|')
	
	SELECT
		 MAX(RowsReceivedCount) AS RowsReceivedCount
		,SUM(LoadedCount) AS LoadedCount
		,SUM(FailedValidationCount) AS FailedValidationCount
		,SUM(PassedValidationCount) AS PassedValidationCount
		,SUM(DuplicateRowsCount) AS DuplicateCount
		,SUM(BatchCreatedCount) AS BatchCreatedCount
		,SUM(FileCreatedCount) AS FileCreatedCount
		,SUM(SubmittedCount) AS SubmittedCount
		,SUM(FERASAcceptedCount) AS FERASAcceptedCount
		,SUM(FERASRejectedCount) AS FERASRejectedCount
		,SUM(RAPSReturnRejectedDuplicateCount) AS RAPSReturnRejectedDuplicateCount
		,SUM(RAPSReturnRejectedNonDuplicateCount) AS RAPSReturnRejectedNonDuplicateCount
		,SUM(RAPSReturnAcceptedCount) AS RAPSReturnAcceptedCount
		,LineOfBusiness
		,PlanID
		,OriginalFileName
		,ReceivedDate
		,SplitFileName
		,FileType
	FROM raps.QRAPSReconciliationSummary WITH (NOLOCK)
	WHERE CAST(ReceivedDate AS DATE) BETWEEN @GENERALSTARTDATE AND @GENERALENDDATE
	AND (
		ISNULL(LineOfBusiness, 'N/A') IN (
			SELECT Item
			FROM @tblLineOfBusiness
		)
		OR @LineOfBusiness = 'All Line of Businesses'
	)
	AND (
		ISNULL(PlanID, 'N/A') IN (
			SELECT Item
			FROM @tblPlanID
		)
		OR @PlanID = 'All Plan IDs'
	)
	GROUP BY
		LineOfBusiness
		,PlanID
		,OriginalFileName
		,ReceivedDate
		,SplitFileName
		,FileType

END