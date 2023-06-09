
    CREATE TABLE rev.EstRecevBuildup
        (
        [EstRecevBuildupID] [INT] IDENTITY(1, 1)
                                     NOT NULL ,
          PlanIdentifier INT ,
          HICN VARCHAR(12) ,
          Factor DECIMAL(20, 4) ,
          HCCLabel VARCHAR(19) ,
          AgeGrp INT ,
          Payment_year VARCHAR(4) ,
          MYU VARCHAR(1) ,
          Populated DATETIME ,
          HCCHierarchy VARCHAR(19) ,
          FactorHierarchy DECIMAL(20, 4) ,
          HCCDeleteHierarchy VARCHAR(19) ,
          FactorDeleteHierarchy DECIMAL(20, 4) ,
          RAFTRestated VARCHAR(4) ,
          ModelYear VARCHAR(4) ,
          DeleteFlag INT ,
          DateForFactors DATETIME ,
          HCCNumber INT ,
          FactorType VARCHAR(4)
        )
