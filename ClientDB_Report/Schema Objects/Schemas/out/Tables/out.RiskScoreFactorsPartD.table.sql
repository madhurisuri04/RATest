CREATE TABLE out.RiskScoreFactorsPartD
    (
      ID BIGINT IDENTITY(1, 1)
                NOT NULL ,
      PaymentYear VARCHAR(4) NOT NULL ,
      MYUFlag CHAR(1) NOT NULL ,
      PlanIdentifier INT NULL ,
      HICN VARCHAR(12) NULL ,
      AgeGrpID INT NULL ,
      HCCLabel VARCHAR(19) NULL ,
      Factor DECIMAL(20, 4) NULL ,
      HCCHierarchy VARCHAR(19) NULL ,
      FactorHierarchy DECIMAL(20, 4) NULL ,
      HCCDeleteHierarchy VARCHAR(19) NULL ,
      FactorDeleteHierarchy DECIMAL(20, 4) NULL ,
      PartDRAFTProjected VARCHAR(4) NULL ,
      PartDRAFTMMR VARCHAR(4) NULL ,
      ModelYear VARCHAR(4) NULL ,
      DeleteFlag INT NULL ,
      DateForFactors DATETIME NULL ,
      HCCNumber INT NULL ,
      Aged INT NULL ,
      SourceType VARCHAR(4) NULL ,
      PartitionKey INT NOT NULL ,
      LoadDate DATETIME NULL ,
      UserID VARCHAR(128) NOT NULL
    )

ON  pscheme_PYMYST(PartitionKey) 