CREATE TABLE [hst].EstRecvDetailPartD
    (
      ID BIGINT IDENTITY(1, 1)
                    NOT NULL ,
      HPlanID VARCHAR(5) NULL ,
      PaymentYear INT NOT NULL ,
      MYUFlag CHAR(1) NOT NULL ,
      DateForFactors VARCHAR(30) NULL ,
      HICN VARCHAR(20) NULL ,
      PayStart SMALLDATETIME NULL ,
      RAFTRestated VARCHAR(5) NULL ,
      RAFTMMR VARCHAR(5) NULL ,
      Agegrp VARCHAR(8) NULL ,
      Sex CHAR(2) NULL ,
      Medicaid VARCHAR(5) NULL ,
      ORECRestated CHAR(2) NULL ,
      MaxMOR VARCHAR(8) NULL ,
      MidYearUpdateFlag CHAR(1) NULL ,
      AgeGroupID VARCHAR(4) NULL ,
      GenderID CHAR(1) NULL ,
      SCC VARCHAR(10) NULL ,
      PBP VARCHAR(10) NULL ,
      Bid DECIMAL(19, 4) NULL ,
      NewEnrolleeFlagError CHAR(2) NULL ,
      MonthsInDCP INT NULL ,
      ISARUsed CHAR(1) NULL ,
      RiskScoreCalculated DECIMAL(10, 3) NULL ,
      RiskScoreMMR DECIMAL(10, 4) NULL ,
      RSDifference DECIMAL(19, 4) NULL ,
      EstimatedRecvAmount DECIMAL(12, 4) NULL ,
      ProjectedRiskScore DECIMAL(10, 3) NULL ,
      EstimatedRecvAmountAfterDelete DECIMAL(12, 4) NULL ,
      AmountDeleted DECIMAL(12, 4) NULL ,
      RiskScoreNewAfterDelete DECIMAL(10, 3) NULL ,
      DifferenceAfterDelete DECIMAL(19, 4) NULL ,
      ProjectedRiskScoreAfterDelete DECIMAL(10, 3) NULL ,
      RAPSProjectedRiskScore DECIMAL(10, 3) NULL ,
      RAPSProjectedRiskScoreAfterDelete DECIMAL(10, 3) NULL ,
      EDSProjectedRiskScore DECIMAL(10, 3) NULL ,
      EDSProjectedRiskScoreAfterDelete DECIMAL(10, 3) NULL ,
      MemberMonth CHAR(1) NULL ,
      ActualFinalPaid DECIMAL(20, 3) NULL ,
      MARiskRevenueRecalc DECIMAL(20, 3) NULL ,
      MARiskRevenueVariance DECIMAL(20, 3) NULL ,
      TotalPremiumYTD DECIMAL(20, 3) NULL ,
      MidYearUpdateActual DECIMAL(20, 3) NULL ,
      LowIncomeMultiplier DECIMAL(19, 4) NULL ,
      PartDBasicPremiumAmount DECIMAL(20, 3) NULL ,
      PlanIdentifier SMALLINT NULL ,
      AgedStatus VARCHAR(15) NULL ,
      SourceType VARCHAR(4) NULL ,
      PartitionKey INT NOT NULL ,
      LoadDate DATETIME NULL,
	  UserID VARCHAR(128) NOT NULL,
	  LastAssignedHICN VARCHAR(20) NULL 
	)
