/************************************************************************        
* Name			:	[rev].EstRecvDetailPartCExtract    			     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	03/03/2017											*	
* Ticket        :   
* Version		:        												*
* Description	:	Populates Demographics into etl table				*
* SP Call		:	EXEC [rev].[EstRecvDetailPartCExtract] '2016', 'N', 'H3204', 'C'

***************************************************************************/   
/********************************************************************************************
TICKET		DATE			NAME                DESCRIPTION
66117       8/7/2017        Madhuri Suri		Add MYU Flag Parameter
66532		8/24/2017		Rakshit Lall		Added a ViewThrough parameter
66532		8/28/2017		Rakshit Lall		MYUFlag changed from VARCHAR(1) TO CHAR(1), Item value changed to 800 from 1024 + Added GROUPBY
***********************************************************************************************/  

CREATE PROCEDURE [rev].[EstRecvDetailPartCExtract] 
    (
      @PaymentYear VARCHAR(4) ,
      @MYUFlag CHAR (1),
      @Plan VARCHAR(1000) ,
      @RAFactorType VARCHAR(100),
      @ViewThrough INT = 1
    )
    
WITH RECOMPILE
    
AS
BEGIN
--Test
--DECLARE @PaymentYear VARCHAR(4) =2016 ,
 -- @MYU VARCHAR (1)= 'N',
 -- @Plan VARCHAR(1000)= 'H9615' ,
 -- @RAFactorType VARCHAR(50)= 'C'
    SET NOCOUNT ON
    
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  
IF (@ViewThrough = 1)
BEGIN  
     
    DECLARE 
		@PY VARCHAR(4) = @PaymentYear,
		@Pln VARCHAR(1000) = @Plan,
		@RFT VARCHAR(100) = @RAFactorType, 
		@MYU CHAR (1) = @MYUFlag

   
IF OBJECT_ID('tempdb..#HPlan') IS NOT NULL
     DROP TABLE #HPlan
     
CREATE TABLE #HPlan
(Item VARCHAR(800) PRIMARY KEY)

IF OBJECT_ID('tempdb..#RAFT') IS NOT NULL
     DROP TABLE #RAFT
     
CREATE TABLE #RAFT
(Item VARCHAR(800) PRIMARY KEY)

INSERT INTO #HPlan (Item)
SELECT Item
FROM dbo.fnsplit(@Pln, ',')

INSERT INTO #RAFT
        ( Item )

SELECT Item
FROM dbo.fnsplit(@RFT, ',')

SELECT HPlanID
     ,PaymentYear
     ,MYUFlag
     ,DateForFactors
     ,HICN
     ,PayStart
     ,RAFTRestated
     ,RAFTMMR
     ,Agegrp
     ,Sex
     ,Medicaid
     ,ORECRestated
     ,MAXMOR
     ,MidYearUpdateFlag
     ,AgeGroupID
     ,GenderID
     ,SCC
     ,PBP
     ,Bid
     ,NewEnrolleeFlagError
     ,MonthsInDCP
     ,ISARUsed
     ,RiskScoreCalculated
     ,RiskScoreMMR
     ,RSDifference
     ,EstimatedRecvAmount
     ,ProjectedRiskScore
     ,EstimatedRecvAmountAfterDelete
     ,AmountDeleted
     ,RiskScoreNewAfterDelete
     ,DifferenceAfterDelete
     ,ProjectedRiskScoreAfterDelete
     ,MemberMonth
     ,ActualFinalPaid
     ,MARiskRevenue_A_B
     ,MARiskRevenueRecalc
     ,MARiskRevenueVariance
     ,TotalPremiumYTD
     ,MidYearUpdateActual
     ,Populated
     ,ESRD
     ,DefaultInd
     ,PlanIdentifier
     ,AgedStatus
     ,SourceType
     ,PartitionKey
     ,RAPSProjectedRiskScore
     ,RAPSProjectedRiskScoreAfterDelete
     ,EDSProjectedRiskScore
     ,EDSProjectedRiskScoreAfterDelete
FROM rev.EstRecvDetailPartC
WHERE PaymentYear = @PY
     AND MYUFlag = @MYU
     AND (
           HPlanID IN (
                 SELECT Item
                 FROM #HPlan
                 )
           OR (@Pln IS NULL)
           )
     AND (
           RAFTRestated IN (
                 SELECT Item
                 FROM #RAFT
                 )
           OR (@RFT IS NULL)
           )
GROUP BY
	HPlanID
     ,PaymentYear
     ,MYUFlag
     ,DateForFactors
     ,HICN
     ,PayStart
     ,RAFTRestated
     ,RAFTMMR
     ,Agegrp
     ,Sex
     ,Medicaid
     ,ORECRestated
     ,MAXMOR
     ,MidYearUpdateFlag
     ,AgeGroupID
     ,GenderID
     ,SCC
     ,PBP
     ,Bid
     ,NewEnrolleeFlagError
     ,MonthsInDCP
     ,ISARUsed
     ,RiskScoreCalculated
     ,RiskScoreMMR
     ,RSDifference
     ,EstimatedRecvAmount
     ,ProjectedRiskScore
     ,EstimatedRecvAmountAfterDelete
     ,AmountDeleted
     ,RiskScoreNewAfterDelete
     ,DifferenceAfterDelete
     ,ProjectedRiskScoreAfterDelete
     ,MemberMonth
     ,ActualFinalPaid
     ,MARiskRevenue_A_B
     ,MARiskRevenueRecalc
     ,MARiskRevenueVariance
     ,TotalPremiumYTD
     ,MidYearUpdateActual
     ,Populated
     ,ESRD
     ,DefaultInd
     ,PlanIdentifier
     ,AgedStatus
     ,SourceType
     ,PartitionKey
     ,RAPSProjectedRiskScore
     ,RAPSProjectedRiskScoreAfterDelete
     ,EDSProjectedRiskScore
     ,EDSProjectedRiskScoreAfterDelete
ORDER BY HPlanID
     ,RAFTRestated
     ,PayStart DESC
	
END	         

END