/*******************************************************************************************************************************
* Name			:	rpt.EstRecvSummaryPartCByPBP
* Type 			:	Stored Procedure          
* Author       	:	Rakshit Lall
* TFS#          :   
* Date          :	7/28/2017
* Version		:	1.3
* Project		:	SP for generating the output for the "Part C Estimated Receivable, Summary" SSRS report from RE
* SP call		:	Exec rpt.EstRecvSummaryPartCByPBP '2017', 'Y', 'H3204, H3206' --, 'SummaryByPBP'
* Version History :
  Author			Date		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------
	Rakshit Lall	6/28/2017	1.1			65324			Modified the SP to use AVG from HICN Risk Scores
	Rakshit Lall	7/17/2017	1.2			65872			Commented out the filter conditions in the subquery for better performance
	Rakshit Lall	7/28/2017	1.3			66112			Use permanent table for fetching the data
*********************************************************************************************************************************/

CREATE PROCEDURE [rpt].[EstRecvSummaryPartCByPBP]
	@PaymentYear INT,
	@MYUFlag VARCHAR(1),
	@PlanID VARCHAR(200),
	@ViewBy VARCHAR(50) = NULL

WITH RECOMPILE
	
AS
BEGIN

SET NOCOUNT ON
	
DECLARE @Error_Message VARCHAR(8000)
BEGIN TRY

DECLARE 
	@PYear INT = @PaymentYear,
	@Flag VARCHAR(1) = @MYUFlag,
	@PID VARCHAR(200) = @PlanID,
	@VBy VARCHAR(50) = @ViewBy

IF OBJECT_ID('TempDB..#tempPID') IS NOT NULL
DROP TABLE #tempPID

CREATE TABLE #tempPID
	(
		Item VARCHAR(200)
	)

INSERT INTO #tempPID
	(
		Item
	)
SELECT Item 
FROM dbo.fnsplit(@PID, ',')

SELECT
	PaymentYear,
	MYUFlag,
	PBP,
	Members,
	MemberMonths,
	RAPSProjectedRiskScore,
	EDSProjectedRiskScore,
	ProjectedRiskScore,
	CurrentScore,
	LastPaymentMonth,
	EstimatedReceivable,
	EstimatedReceivableAfterDelete,
	AmountDeleted,
	DBPlanID
FROM rev.EstRecvSummaryPartC
WHERE
	PaymentYear = @PYear
AND	
	MYUFlag = @Flag
AND 
	EXISTS (SELECT 1 FROM #tempPID tp WHERE DBPlanID = tp.Item)
AND
	Category = 'SummaryByPBP'
GROUP BY
	PaymentYear,
	MYUFlag,
	PBP,
	Members,
	MemberMonths,
	RAPSProjectedRiskScore,
	EDSProjectedRiskScore,
	ProjectedRiskScore,
	CurrentScore,
	LastPaymentMonth,
	EstimatedReceivable,
	EstimatedReceivableAfterDelete,
	AmountDeleted,
	DBPlanID
ORDER BY
	DBPlanID,
	EstimatedReceivable DESC

END TRY
	BEGIN CATCH
	      DECLARE @ErrorMsg VARCHAR(2000)
		  SET @ErrorMsg = 'Error: ' + ISNULL(Error_Procedure(),'script') + ': ' +  Error_Message() +
                           ', Error Number: ' + CAST(Error_Number() AS VARCHAR(10)) + ' Line: ' + 
                           CAST(Error_Line() AS VARCHAR(50))
   
		RAISERROR (@ErrorMsg, 16, 1)
	END CATCH
	
END