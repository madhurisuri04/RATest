 CREATE TABLE etl.RiskScoreFactorsPartC
        (
          [ID] BIGINT IDENTITY(1, 1)
                                    NOT NULL ,                                    
          PaymentYear VARCHAR(4) NOT NULL ,
          MYUFlag VARCHAR(1) NOT NULL ,
          PlanIdentifier INT NULL,
          HICN VARCHAR(12) NULL,
          AgeGrpID INT NULL,
          Populated DATETIME NULL,
          HCCLabel VARCHAR(19)NULL ,          
          Factor DECIMAL(20, 4)NULL ,
          HCCHierarchy VARCHAR(19)NULL ,
          FactorHierarchy DECIMAL(20, 4) NULL ,
          HCCDeleteHierarchy VARCHAR(19) NULL ,
          FactorDeleteHierarchy DECIMAL(20, 4) NULL,
          PartCRAFTProjected VARCHAR(4) NULL ,
          PartCRAFTMMR VARCHAR(4) NULL ,
          ModelYear VARCHAR(4) NULL,
          DeleteFlag INT NULL,
          DateForFactors DATETIME NULL,
          HCCNumber INT NULL,
          Aged INT NULL,
          SourceType VARCHAR(4) NULL ,
          PartitionKey INT NOT NULL
        )
ON  pscheme_PYMYST(PartitionKey) 
