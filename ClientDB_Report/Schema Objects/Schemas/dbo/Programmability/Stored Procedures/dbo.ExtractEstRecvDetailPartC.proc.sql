/************************************************************************        
* Name          :   [dbo].ExtractEstRecvDetailPartC
* Type          :   Stored Procedure           
* Author        :   Madhuri Suri                          
* Date          :   08/24/2017
* Ticket        :   
* Version       :                                   
* Description   :   Extract proc for Report Extract Function
* SP Call       :   EXEC [dbo].[ExtractEstRecvDetailPartC] 7
***********************************************************************************************/  
CREATE PROCEDURE [dbo].[ExtractEstRecvDetailPartC] 
    (
            @ExtractRequestID BIGINT
    )
    
AS
BEGIN
 
SET NOCOUNT ON
            
DECLARE 
        @PY VARCHAR(4)
      , @MYU CHAR(1)
      , @Pln VARCHAR(1000)
      , @RFT VARCHAR(100) 
      
SELECT 
            @PY = [PaymentYear] ,
            @MYU = [MYU], 
            @Pln = [Plan], 
            @RFT = [RAFactorType]
      FROM 
            (
                  SELECT 
                        ParameterName,
                        ParameterValue
                  FROM dbo.ExtractRequestParameter
                  WHERE 
                        ExtractRequestID = @ExtractRequestID
            ) a
      PIVOT(MAX(ParameterValue) FOR ParameterName IN ([PaymentYear], [MYU], [Plan], [RAFactorType], [UserID])) AS VALUE
      
DECLARE @HPlan TABLE
      (
            Item VARCHAR(800) PRIMARY KEY
      )
      
DECLARE @RAFT TABLE
      (
            Item VARCHAR(800) PRIMARY KEY
      )     
 
INSERT INTO @HPlan 
      (
            Item
      )
SELECT Item
FROM dbo.fnsplit(@Pln, ',')
 
INSERT INTO @RAFT
      (
            Item 
      )
 
SELECT Item
FROM dbo.fnsplit(@RFT, ',')
 
SELECT  'HPlanID' AS HPlanID,
        'PaymentYear' AS PaymentYear,
        'MYUFlag' AS MYUFlag,
        'DateForFactors' AS DateForFactors ,
        'HICN' AS HICN ,
        'PayStart' AS PayStart ,
        'RAFTRestated' AS RAFTRestated ,
        'RAFTMMR' AS RAFTMMR ,
        'Agegrp' AS Agegrp ,
        'Sex' AS Sex ,
        'Medicaid' AS Medicaid ,
        'ORECRestated' AS ORECRestated ,
        'MAXMOR' AS MAXMOR ,
        'MidYearUpdateFlag' AS MidYearUpdateFlag ,
        'AgeGroupID' AS AgeGroupID ,
        'GenderID' AS GenderID ,
        'SCC' AS SCC ,
        'PBP' AS PBP ,
        'Bid' AS Bid ,
        'NewEnrolleeFlagError' AS NewEnrolleeFlagError ,
        'MonthsInDCP' AS MonthsInDCP ,
        'ISARUsed' AS ISARUsed ,
        'RiskScoreCalculated' AS RiskScoreCalculated ,
        'RiskScoreMMR' AS RiskScoreMMR ,
        'RSDifference' AS RSDifference ,
        'EstimatedRecvAmount' AS EstimatedRecvAmount ,
        'ProjectedRiskScore' AS ProjectedRiskScore ,
        'EstimatedRecvAmountAfterDelete' AS EstimatedRecvAmountAfterDelete ,
        'AmountDeleted' AS AmountDeleted ,
        'RiskScoreNewAfterDelete' AS RiskScoreNewAfterDelete ,
        'DifferenceAfterDelete' AS DifferenceAfterDelete ,
        'ProjectedRiskScoreAfterDelete' AS ProjectedRiskScoreAfterDelete ,
        'MemberMonth' AS MemberMonth ,
        'ActualFinalPaid' AS ActualFinalPaid ,
        'MARiskRevenue_A_B' AS MARiskRevenue_A_B ,
        'MARiskRevenueRecalc' AS MARiskRevenueRecalc ,
        'MARiskRevenueVariance' AS MARiskRevenueVariance ,
        'TotalPremiumYTD' AS TotalPremiumYTD ,
        'MidYearUpdateActual' AS MidYearUpdateActual ,
        'Populated' AS Populated ,
        'ESRD' AS ESRD ,
        'DefaultInd' AS DefaultInd ,
        'PlanIdentifier' AS PlanIdentifier ,
        'AgedStatus' AS AgedStatus ,
        'SourceType' AS SourceType ,
        'PartitionKey' AS PartitionKey ,
        'RAPSProjectedRiskScore' AS RAPSProjectedRiskScore ,
        'RAPSProjectedRiskScoreAfterDelete' AS RAPSProjectedRiskScoreAfterDelete ,
        'EDSProjectedRiskScore' AS EDSProjectedRiskScore ,
        'EDSProjectedRiskScoreAfterDelete' AS EDSProjectedRiskScoreAfterDelete
        
UNION ALL
 
SELECT
		HPlanID ,
        CONVERT(VARCHAR(4), PaymentYear) ,
        MYUFlag,
        DateForFactors ,
        HICN ,
        CONVERT(VARCHAR(12), PayStart) ,
        RAFTRestated ,
        RAFTMMR ,
        Agegrp ,
        Sex ,
        Medicaid ,
        ORECRestated ,
        MAXMOR ,
        MidYearUpdateFlag ,
        AgeGroupID ,
        GenderID ,
        SCC ,
        PBP ,
        CONVERT(VARCHAR(50), Bid) ,
        NewEnrolleeFlagError ,
        CONVERT(VARCHAR(50), MonthsInDCP) ,
        ISARUsed ,
        CONVERT(VARCHAR(50), RiskScoreCalculated) ,
        CONVERT(VARCHAR(50), RiskScoreMMR) ,
        CONVERT(VARCHAR(50), RSDifference) RSDifference ,
        CONVERT(VARCHAR(50), EstimatedRecvAmount) ,
        CONVERT(VARCHAR(50), ProjectedRiskScore) ,
        CONVERT(VARCHAR(50), EstimatedRecvAmountAfterDelete) ,
        CONVERT(VARCHAR(50), AmountDeleted) ,
        CONVERT(VARCHAR(50), RiskScoreNewAfterDelete) ,
        CONVERT(VARCHAR(50), DifferenceAfterDelete) ,
        CONVERT(VARCHAR(50), ProjectedRiskScoreAfterDelete) ,
        CONVERT(VARCHAR(50), MemberMonth) ,
        CONVERT(VARCHAR(50), ActualFinalPaid) ,
        CONVERT(VARCHAR(50), MARiskRevenue_A_B) ,
        CONVERT(VARCHAR(50), MARiskRevenueRecalc) ,
        CONVERT(VARCHAR(50), MARiskRevenueVariance) ,
        CONVERT(VARCHAR(50), TotalPremiumYTD) ,
        CONVERT(VARCHAR(50), MidYearUpdateActual) ,
        CONVERT(VARCHAR(50), Populated) ,
        ESRD ,
        DefaultInd ,
        CONVERT(VARCHAR(50), PlanIdentifier) ,
        AgedStatus ,
        SourceType ,
        CONVERT(VARCHAR(50), PartitionKey) ,
        CONVERT(VARCHAR(50), RAPSProjectedRiskScore) ,
        CONVERT(VARCHAR(50), RAPSProjectedRiskScoreAfterDelete) ,
        CONVERT(VARCHAR(50), EDSProjectedRiskScore) ,
        CONVERT(VARCHAR(50), EDSProjectedRiskScoreAfterDelete)
FROM rev.EstRecvDetailPartC C WITH(NOLOCK)
WHERE 
      PaymentYear = @PY
AND 
      (EXISTS
            (
                  SELECT 1 FROM @HPlan H
                  WHERE C.HPlanID = H.Item
            )
      OR (@Pln IS NULL)
      )
AND 
      (EXISTS
            (
                  SELECT 1 FROM @RAFT R
                  WHERE C.RAFTRestated = R.Item
            )
      OR (@RFT IS NULL)
      )
AND 
      MYUFlag = @MYU
GROUP BY
	HPlanID ,
        CONVERT(VARCHAR(4), PaymentYear) ,
        MYUFlag,
        DateForFactors ,
        HICN ,
        CONVERT(VARCHAR(12), PayStart) ,
        RAFTRestated ,
        RAFTMMR ,
        Agegrp ,
        Sex ,
        Medicaid ,
        ORECRestated ,
        MAXMOR ,
        MidYearUpdateFlag ,
        AgeGroupID ,
        GenderID ,
        SCC ,
        PBP ,
        CONVERT(VARCHAR(50), Bid) ,
        NewEnrolleeFlagError ,
        CONVERT(VARCHAR(50), MonthsInDCP) ,
        ISARUsed ,
        CONVERT(VARCHAR(50), RiskScoreCalculated) ,
        CONVERT(VARCHAR(50), RiskScoreMMR) ,
        CONVERT(VARCHAR(50), RSDifference) ,
        CONVERT(VARCHAR(50), EstimatedRecvAmount) ,
        CONVERT(VARCHAR(50), ProjectedRiskScore) ,
        CONVERT(VARCHAR(50), EstimatedRecvAmountAfterDelete) ,
        CONVERT(VARCHAR(50), AmountDeleted) ,
        CONVERT(VARCHAR(50), RiskScoreNewAfterDelete) ,
        CONVERT(VARCHAR(50), DifferenceAfterDelete) ,
        CONVERT(VARCHAR(50), ProjectedRiskScoreAfterDelete) ,
        CONVERT(VARCHAR(50), MemberMonth) ,
        CONVERT(VARCHAR(50), ActualFinalPaid) ,
        CONVERT(VARCHAR(50), MARiskRevenue_A_B) ,
        CONVERT(VARCHAR(50), MARiskRevenueRecalc) ,
        CONVERT(VARCHAR(50), MARiskRevenueVariance) ,
        CONVERT(VARCHAR(50), TotalPremiumYTD) ,
        CONVERT(VARCHAR(50), MidYearUpdateActual) ,
        CONVERT(VARCHAR(50), Populated) ,
        ESRD ,
        DefaultInd ,
        CONVERT(VARCHAR(50), PlanIdentifier) ,
        AgedStatus ,
        SourceType ,
        CONVERT(VARCHAR(50), PartitionKey) ,
        CONVERT(VARCHAR(50), RAPSProjectedRiskScore) ,
        CONVERT(VARCHAR(50), RAPSProjectedRiskScoreAfterDelete) ,
        CONVERT(VARCHAR(50), EDSProjectedRiskScore) ,
        CONVERT(VARCHAR(50), EDSProjectedRiskScoreAfterDelete)        
 
END