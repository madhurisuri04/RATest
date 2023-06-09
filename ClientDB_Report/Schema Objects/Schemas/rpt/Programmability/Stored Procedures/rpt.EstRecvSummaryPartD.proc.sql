/*******************************************************************************************************************************
* Name			:	rpt.EstRecvSummaryPartD
* Type 			:	Stored Procedure          
* Author       	:	Madhuri Suri
* TFS#          :   
* Date          :	4/10/2018
* Version		:	1.3
* Project		:	SP for generating the output for the "Part D Estimated Receivable, Summary" SSRS report from RE
* SP call		:	Exec rpt.EstRecvSummaryPartD '2017', 'N', 'H3305', NULL
* Version History :
  Author			Date		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------
*********************************************************************************************************************************/

CREATE PROCEDURE [rpt].[EstRecvSummaryPartD]
	@PaymentYear INT,
	@MYUFlag VARCHAR(1),
	@PlanID VARCHAR(200),
	@ViewBy VARCHAR(50) = NULL

	
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
	Members,
	MemberMonths,
	MonthsInDCP,
	EstimatedReceivable,
	EstimatedReceivableAfterDelete,
	AmountDeleted,
	TotalPremiumYTD,
	RAFactorType,
	LastPaymentMonth,
	AgedStatus,
	DBPlanID,
	RAPSProjectedRiskScore,
	RAPSProjectedRiskScoreAfterDelete,
	EDSProjectedRiskScore,
	EDSProjectedRiskScoreAfterDelete,
	ProjectedRiskScore,
	CurrentScore,
	ProjectedRiskScoreAfterDelete
FROM rev.EstRecvSummaryPartD
WHERE
	PaymentYear = @PYear
AND	
	MYUFlag = @Flag
AND 
	EXISTS (SELECT 1 FROM #tempPID tp WHERE DBPlanID = tp.Item)
AND
	Category = 'Summary'
GROUP BY
	PaymentYear,
	MYUFlag,
	Members,
	MemberMonths,
	MonthsInDCP,
	EstimatedReceivable,
	EstimatedReceivableAfterDelete,
	AmountDeleted,
	TotalPremiumYTD,
	RAFactorType,
	LastPaymentMonth,
	AgedStatus,
	DBPlanID,
	RAPSProjectedRiskScore,
	RAPSProjectedRiskScoreAfterDelete,
	EDSProjectedRiskScore,
	EDSProjectedRiskScoreAfterDelete,
	ProjectedRiskScore,
	CurrentScore,
	ProjectedRiskScoreAfterDelete
ORDER BY
	DBPlanID,
	RAFactorType,
	MonthsInDCP DESC,
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