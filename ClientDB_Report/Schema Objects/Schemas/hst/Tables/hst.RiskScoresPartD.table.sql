CREATE TABLE hst.RiskScoresPartD
    (
      ID BIGINT IDENTITY(1, 1)
                NOT NULL ,
      Planidentifier INT NULL ,
      HICN VARCHAR(12) NULL ,
      PaymentYear VARCHAR(4) NOT NULL ,
      MYUFlag CHAR(1) NOT NULL ,
      PartDRAFTProjected VARCHAR(4) NULL ,
      RiskScoreCalculated DECIMAL(20, 4) NULL ,
      ModelYear VARCHAR(4) NULL ,
      DeleteYN INT NULL ,
      DateForFactors DATETIME NULL ,
      SourceType VARCHAR(4) NULL ,
      PartitionKey INT NOT NULL ,
      LoadDate DATETIME NULL ,
      UserID VARCHAR(128) NOT NULL
    )