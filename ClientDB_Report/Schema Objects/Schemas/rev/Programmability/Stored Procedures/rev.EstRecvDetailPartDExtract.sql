/************************************************************************        
* Name			:	[rev].EstRecvDetailPartDExtract    			     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	03/20/2018											*	
* Ticket        :   
* Version		:        												*
* Description	:	Detail export for Part D ER			             	*
* SP Call		:	EXEC [rev].[EstRecvDetailPartDExtract] '2016', 'H3204', 'E,C'

***************************************************************************/   
/********************************************************************************************
TICKET       DATE              NAME                DESCRIPTION
***********************************************************************************************/  
CREATE  PROCEDURE [rev].[EstRecvDetailPartDExtract] 
    (
      @PaymentYear VARCHAR(4) ,
      @MYUFlag CHAR (1),
      @Plan VARCHAR(1000) ,
      @RAFactorType VARCHAR(100),
      @ViewThrough INT = 1
      
    )
        
AS
BEGIN
--Test
--DECLARE @PaymentYear VARCHAR(4) =2016 ,
 -- @MYU VARCHAR (1)= 'N',
 -- @Plan VARCHAR(1000)= 'H9615' ,
 -- @RAFactorType VARCHAR(50)= 'C'
    SET NOCOUNT ON
    
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
     ,MARiskRevenueRecalc
     ,MARiskRevenueVariance
     ,TotalPremiumYTD
     ,MidYearUpdateActual
     ,LoadDate
     ,PlanIdentifier
     ,AgedStatus
     ,SourceType
     ,PartitionKey
     ,RAPSProjectedRiskScore
     ,RAPSProjectedRiskScoreAfterDelete
     ,EDSProjectedRiskScore
     ,EDSProjectedRiskScoreAfterDelete
FROM rev.EstRecvDetailPartD
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
ORDER BY HPlanID
     ,RAFTRestated
     ,PayStart DESC
	         

END
END 