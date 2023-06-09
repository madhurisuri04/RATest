/*******************************************************************************************************************************
* Name			:	rev.LoadEstRecvSummaryPartD
* Type 			:	Stored Procedure          
* Author       	:	Madhuri Suri	
* TFS#          :   
* Date          :	4/20/2018
* Version		:	1.1
* Project		:	Child SP that will be called by the "rev.WrapperLoadEstRecvSummaryPartD" to load "EstRecvSummaryPartD" table
* SP call		:	Exec rev.LoadEstRecvSummaryPartD '2016'
* Version History :
  Author			Date		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------ 
 Anand               09/22/2020  1.1         RRI-229/79617   Add Row Count Out Parameter
*********************************************************************************************************************************/

CREATE PROCEDURE [rev].[LoadEstRecvSummaryPartD]
(
	@PaymentYear INT,
	@RowCount INT OUT
)
AS
BEGIN

SET NOCOUNT ON

DECLARE 
	@Today DATETIME = GETDATE(),
	@User VARCHAR(256) = SUSER_NAME()

DECLARE @Error_Message VARCHAR(8000)
BEGIN TRY

IF OBJECT_ID('TempDB..#SummaryAvg') IS NOT NULL
DROP TABLE #SummaryAvg

IF OBJECT_ID('TempDB..#SummaryAvgByPBP') IS NOT NULL
DROP TABLE #SummaryAvgByPBP

CREATE TABLE #SummaryAvg
(
	PaymentYear INT NOT NULL,
	MYUFlag VARCHAR(1) NOT NULL,
	MonthsInDCP INT NULL,
	RAFactorType VARCHAR(5) NULL,
	AgedStatus VARCHAR(15) NULL,
	HPlanID VARCHAR(5) NULL,
	RAPSProjectedRiskScore DECIMAL(10,3) NULL,
	RAPSProjectedRiskScoreAfterDelete DECIMAL(10,3) NULL,
	EDSProjectedRiskScore DECIMAL(10,3) NULL,
	EDSProjectedRiskScoreAfterDelete DECIMAL(10,3) NULL,
	ProjectedRiskScore DECIMAL(10,3) NULL,
	RiskScoreCalculated DECIMAL(10,3) NULL,
	ProjectedRiskScoreAfterDelete DECIMAL(10,3) NULL
)

CREATE TABLE #SummaryAvgByPBP
(
	PaymentYear INT NOT NULL,
	MYUFlag VARCHAR(1) NOT NULL,
	PBP VARChar(10) NULL,
	HPlanID VARCHAR(5) NULL,
	RAPSProjectedRiskScore DECIMAL(10,3) NULL,
	EDSProjectedRiskScore DECIMAL(10,3) NULL,
	ProjectedRiskScore DECIMAL(10,3) NULL,
	CurrentScore DECIMAL(10,3) NULL
)

INSERT INTO #SummaryAvg
(
	PaymentYear,
	MYUFlag,
	MonthsInDCP,
	RAFactorType,
	AgedStatus,
	HPlanID,
	RAPSProjectedRiskScore,
	RAPSProjectedRiskScoreAfterDelete,
	EDSProjectedRiskScore,
	EDSProjectedRiskScoreAfterDelete,
	ProjectedRiskScore,
	RiskScoreCalculated,
	ProjectedRiskScoreAfterDelete
)
SELECT 
      PaymentYear, 
      MYUFlag,
      MonthsInDCP, 
      RAFTRestated, 
      CASE 
            WHEN Agedstatus = 'Not Applicable'
            THEN 'NA'
            ELSE AgedStatus 
      END AS AgedStatus, 
      HPlanID, 
      AVG(RAPSProjectedRiskScore) AS RAPSProjectedRiskScore,
      AVG(RAPSProjectedRiskScoreAfterDelete) AS RAPSProjectedRiskScoreAfterDelete,
      AVG(EDSProjectedRiskScore) AS EDSProjectedRiskScore,
      AVG(EDSProjectedRiskScoreAfterDelete) AS EDSProjectedRiskScoreAfterDelete,
      AVG(ProjectedRiskScore) AS ProjectedRiskScore,
      AVG(RiskScoreCalculated) AS CurrentScore,
      AVG(ProjectedRiskScoreAfterDelete) AS ProjectedRiskScoreAfterDelete
FROM 
(
	SELECT
		PaymentYear, 
		HICN,
		MYUFlag,
		MonthsInDCP, 
		RAFTRestated, 
		CASE 
			WHEN Agedstatus = 'Not Applicable'
			THEN 'NA'
			ELSE AgedStatus 
		END AS AgedStatus, 
		HPlanID, 
		RAPSProjectedRiskScore,
		RAPSProjectedRiskScoreAfterDelete,
		EDSProjectedRiskScore,
		EDSProjectedRiskScoreAfterDelete,
		ProjectedRiskScore,
		RiskScoreCalculated,
		ProjectedRiskScoreAfterDelete
	FROM rev.EstRecvDetailPartD WITH(NOLOCK)
	GROUP BY
		PaymentYear, 
		HICN,
		MYUFlag,
		MonthsInDCP, 
		RAFTRestated, 
		AgedStatus,
		HPlanID, 
		RAPSProjectedRiskScore,
		RAPSProjectedRiskScoreAfterDelete,
		EDSProjectedRiskScore,
		EDSProjectedRiskScoreAfterDelete,
		ProjectedRiskScore,
		RiskScoreCalculated,
		ProjectedRiskScoreAfterDelete
 ) HICNRiskScores
WHERE
      PaymentYear = @PaymentYear
GROUP BY
      PaymentYear, 
      MYUFlag,
      MonthsInDCP, 
      RAFTRestated, 
      AgedStatus, 
      HPlanID
      
 /* Load Summary By PBP */
 
 INSERT INTO #SummaryAvgByPBP
(
	PaymentYear,
	MYUFlag,
	PBP,
	HPlanID,
	RAPSProjectedRiskScore,
	EDSProjectedRiskScore,
	ProjectedRiskScore,
	CurrentScore
)
SELECT 
      PaymentYear, 
      MYUFlag, 
      PBP, 
      HPlanID, 
      AVG(RAPSProjectedRiskScore) AS RAPSProjectedRiskScore,
      AVG(EDSProjectedRiskScore) AS EDSProjectedRiskScore,
      AVG(ProjectedRiskScore) AS ProjectedRiskScore,
      AVG(RiskScoreCalculated) AS CurrentScore
FROM 
(
	SELECT 
		PaymentYear, 
		HICN,
		MYUFlag, 
		PBP, 
		HPlanID, 
		RAPSProjectedRiskScore,
		EDSProjectedRiskScore,
		ProjectedRiskScore,
		RiskScoreCalculated
	FROM [rev].[EstRecvDetailPartD] WITH(NOLOCK)
	GROUP BY
		PaymentYear, 
		HICN,
		MYUFlag, 
		PBP, 
		HPlanID, 
		RAPSProjectedRiskScore,
		EDSProjectedRiskScore,
		ProjectedRiskScore,
		RiskScoreCalculated
 ) HICNRiskScores
WHERE
      PaymentYear = @PaymentYear
GROUP BY
      PaymentYear, 
      MYUFlag, 
      PBP, 
      HPlanID
      
/* Load Summary in to ETL table */      
      
INSERT INTO etl.EstRecvSummaryPartD
(
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
	EDSProjectedRiskScore,
	ProjectedRiskScore,
	RAPSProjectedRiskScoreAfterDelete,
	EDSProjectedRiskScoreAfterDelete,
	ProjectedRiskScoreAfterDelete,
	CurrentScore,
	LoadDate,
	UserID,
	Category
)      

SELECT
	A.PaymentYear,
	A.MYUFlag,
	COUNT(DISTINCT C.HICN) AS Members,
	SUM(CAST(C.MemberMonth AS INT)) AS MemberMonths,
	A.MonthsInDCP,
	SUM(C.EstimatedRecvAmount) AS EstimatedReceivable,
	SUM(C.EstimatedRecvAmountAfterDelete) AS EstimatedReceivableAfterDelete,
	SUM(C.AmountDeleted) AS AmountDeleted,
	SUM(C.TotalPremiumYTD) AS TotalPremiumYTD,
	A.RAFactorType,
	MAX(C.PayStart) AS LastPaymentMonth,
	A.AgedStatus,
	A.HPlanID AS DBPlanID,
	A.RAPSProjectedRiskScore,
	A.EDSProjectedRiskScore,
	A.ProjectedRiskScore,
	A.RAPSProjectedRiskScoreAfterDelete,
	A.EDSProjectedRiskScoreAfterDelete,
	A.ProjectedRiskScoreAfterDelete,
	A.RiskScoreCalculated  AS CurrentScore,
	@Today AS LoadDate,
	@User AS UserID,
	'Summary' AS Category
FROM rev.EstRecvDetailPartD C WITH(NOLOCK)
JOIN #SummaryAvg A
	ON A.PaymentYear = C.PaymentYear
	AND	A.MYUFlag = C.MYUFlag
	AND A.MonthsInDCP = C.MonthsInDCP 
	AND A.RAFactorType = C.RAFTRestated
	AND	A.AgedStatus = CASE 
						WHEN C.Agedstatus = 'Not Applicable'
						THEN 'NA'
						ELSE C.AgedStatus 
						END
	AND A.HPlanID = C.HPlanID
GROUP BY
	A.PaymentYear,
	A.MYUFlag,
	A.MonthsInDCP,
	A.RAFactorType,
	A.AgedStatus,
	A.HPlanID,
	A.RAPSProjectedRiskScore,
	A.RAPSProjectedRiskScoreAfterDelete,
	A.EDSProjectedRiskScore,
	A.EDSProjectedRiskScoreAfterDelete,
	A.ProjectedRiskScore,
	A.RiskScoreCalculated,
	A.ProjectedRiskScoreAfterDelete
	
SET @RowCount = Isnull(@@ROWCOUNT,0);

/* Load SummaryByPBP in to ETL table */ 

INSERT INTO etl.EstRecvSummaryPartD
(
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
	DBPlanID,
	LoadDate,
	UserID,
	Category
)

SELECT
	A.PaymentYear,
	A.MYUFlag,
	A.PBP,
	COUNT(DISTINCT HICN) AS Members,
	SUM(CAST(C.MemberMonth AS INT)) AS MemberMonths,
	A.RAPSProjectedRiskScore,
	A.EDSProjectedRiskScore,
	A.ProjectedRiskScore,
	A.CurrentScore,
	MAX(PayStart) AS LastPaymentMonth,
	SUM(EstimatedRecvAmount) AS EstimatedReceivable,
	SUM(EstimatedRecvAmountAfterDelete) AS EstimatedReceivableAfterDelete,
	SUM(AmountDeleted) AS AmountDeleted,
	A.HPlanID AS DBPlanID,
	@Today AS LoadDate,
	@User AS UserID,
	'SummaryByPBP' AS Category
FROM [rev].[EstRecvDetailPartD] C WITH(NOLOCK)
JOIN #SummaryAvgByPBP A
	ON A.PaymentYear = C.PaymentYear
	AND	A.MYUFlag = C.MYUFlag
	AND A.HPlanID = C.HPlanID
	AND A.PBP = C.PBP
GROUP BY
	A.PaymentYear,
	A.MYUFlag,
	A.PBP,
	A.RAPSProjectedRiskScore,
	A.EDSProjectedRiskScore,
	A.ProjectedRiskScore,
	A.CurrentScore,
	A.HPlanID	

SET @RowCount = @RowCount + Isnull(@@ROWCOUNT,0);

/* Load REV from ETL */

INSERT INTO rev.EstRecvSummaryPartD
(
	PaymentYear,
	MYUFlag,
	PBP,
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
	EDSProjectedRiskScore,
	ProjectedRiskScore,
	RAPSProjectedRiskScoreAfterDelete,
	EDSProjectedRiskScoreAfterDelete,
	ProjectedRiskScoreAfterDelete,
	CurrentScore,
	LoadDate,
	UserID,
	Category
)
SELECT
	PaymentYear,
	MYUFlag,
	PBP,
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
	EDSProjectedRiskScore,
	ProjectedRiskScore,
	RAPSProjectedRiskScoreAfterDelete,
	EDSProjectedRiskScoreAfterDelete,
	ProjectedRiskScoreAfterDelete,
	CurrentScore,
	LoadDate,
	UserID,
	Category
FROM etl.EstRecvSummaryPartD WITH(NOLOCK)
WHERE
	PaymentYear = @PaymentYear
GROUP BY
	PaymentYear,
	MYUFlag,
	PBP,
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
	EDSProjectedRiskScore,
	ProjectedRiskScore,
	RAPSProjectedRiskScoreAfterDelete,
	EDSProjectedRiskScoreAfterDelete,
	ProjectedRiskScoreAfterDelete,
	CurrentScore,
	LoadDate,
	UserID,
	Category

SET @RowCount = @RowCount + Isnull(@@ROWCOUNT,0);

END TRY
	BEGIN CATCH
	      DECLARE @ErrorMsg VARCHAR(2000)
		  SET @ErrorMsg = 'Error: ' + ISNULL(Error_Procedure(),'script') + ': ' +  Error_Message() +
                           ', Error Number: ' + CAST(Error_Number() AS VARCHAR(10)) + ' Line: ' + 
                           CAST(Error_Line() AS VARCHAR(50))
   
		RAISERROR (@ErrorMsg, 16, 1)
	END CATCH	

END