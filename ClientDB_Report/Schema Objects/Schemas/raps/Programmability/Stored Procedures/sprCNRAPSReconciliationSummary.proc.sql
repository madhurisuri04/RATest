/***********************************************************************************************************
 Modified By:		Josh Irwin
 Modified Date:		9/4/2019
 Description:		The purpose of this stored procedure is to return data to the CN to RAPS Reconciliation
					Summary SSRS report.
 TFS Ticket:		76752
***********************************************************************************************************/
CREATE PROCEDURE [raps].[sprCNRAPSReconciliationSummary]
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
	--DECLARE @PlanID VARCHAR(2000) = 'All PlanIDs'

	DECLARE @tblLineOfBusiness TABLE (Item VARCHAR(100))
	
	INSERT INTO @tblLineOfBusiness (Item)
	SELECT Item
	FROM dbo.fnSplit(@LineOfBusiness, '|')

	DECLARE @tblPlanID TABLE (Item VARCHAR(100))
	
	INSERT INTO @tblPlanID (Item)
	SELECT Item
	FROM dbo.fnSplit(@PlanID, '|')
	
	SELECT
		SUM(LoadedCount) AS LoadedCount
		,SUM(FailedValidationCount) AS FailedValidationCount
		,SUM(PassedValidationCount) AS PassedValidationCount
		,SUM(DuplicateCount) AS DuplicateCount
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
		,CNRAPSImportID
		,ProcessedDate
	FROM raps.CNRAPSReconciliationSummary WITH (NOLOCK)
	WHERE CAST(ProcessedDate AS DATE) BETWEEN @GENERALSTARTDATE AND @GENERALENDDATE
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
		OR @PlanID = 'All PlanIDs'
	)
	GROUP BY
		LineOfBusiness
		,PlanID
		,CNRAPSImportID
		,ProcessedDate

END