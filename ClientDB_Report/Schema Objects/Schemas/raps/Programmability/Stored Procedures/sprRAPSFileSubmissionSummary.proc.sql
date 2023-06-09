/***********************************************************************************************************
 Modified By:		Josh Irwin
 Modified Date:		3/11/2019
 Description:		The purpose of this stored procedure is to return data to the RAPS File Submission
					Summary SSRS report.
 TFS Ticket:		75333
***********************************************************************************************************/
CREATE PROCEDURE [raps].[sprRAPSFileSubmissionSummary]
	 @GENERALSTARTDATE DATETIME
	,@GENERALENDDATE DATETIME
	,@ViewBy VARCHAR(20)
	,@Source VARCHAR(8000)
	,@PlanID VARCHAR(8000)

AS
BEGIN

	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;
	
	--DECLARE @GENERALSTARTDATE DATETIME = '01/01/2018'
	--DECLARE @GENERALENDDATE DATETIME = '12/31/2018'
	--DECLARE @ViewBy VARCHAR(20) = 'Source'
	--DECLARE @Source VARCHAR(8000) = 'All Sources'
	--DECLARE @PlanID VARCHAR(8000) = 'All PlanIDs'

	DECLARE @tblSource TABLE (Item VARCHAR(100))
	
	INSERT INTO @tblSource (Item)
	SELECT Item
	FROM dbo.fnSplit(@Source, '|')

	DECLARE @tblPlanID TABLE (Item VARCHAR(100))
	
	INSERT INTO @tblPlanID (Item)
	SELECT Item
	FROM dbo.fnSplit(@PlanID, '|')
	
	SELECT
		CASE WHEN @ViewBy = 'Source' THEN ISNULL([Source], 'N/A') ELSE ISNULL(PlanID, 'N/A') END AS GroupBy
		,SubmittedFileName
		,SubmitterID
		,SubmittedDate
		,SubmittedFileID
		,SubmittedFileState
		,SUM(TotalClustersCount) AS TotalClustersCount
		,SUM(InpatientCount) AS InpatientCount
		,SUM(OutpatientCount) AS OutpatientCount
		,SUM(PhysicianCount) AS PhysicianCount
		,SUM(DuplicateStayersCount) AS DuplicateStayersCount
		,SUM(DuplicateNewMemberCount) AS DuplicateNewMemberCount
		,SUM(RAPSReturnAcceptedCount) AS RAPSReturnAcceptedCount
		,SUM(RAPSReturnRejectedNonDuplicateCount) AS RAPSReturnRejectedNonDuplicateCount
	FROM raps.RAPSFileSubmissionSummary WITH (NOLOCK)
	WHERE CAST(SubmittedDate AS DATE) BETWEEN @GENERALSTARTDATE AND @GENERALENDDATE
	AND (
		ISNULL([Source], 'N/A') IN (
			SELECT Item
			FROM @tblSource
		)
		OR @Source = 'All Sources'
	)
	AND (
		ISNULL(PlanID, 'N/A') IN (
			SELECT Item
			FROM @tblPlanID
		)
		OR @PlanID = 'All PlanIDs'
	)
	GROUP BY
		CASE WHEN @ViewBy = 'Source' THEN ISNULL([Source], 'N/A') ELSE ISNULL(PlanID, 'N/A') END
		,SubmittedFileName
		,SubmitterID
		,SubmittedDate
		,SubmittedFileID
		,SubmittedFileState

END