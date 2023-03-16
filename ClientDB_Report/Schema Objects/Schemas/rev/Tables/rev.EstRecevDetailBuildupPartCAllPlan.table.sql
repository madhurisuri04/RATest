CREATE TABLE [rev].[EstRecevDetailBuildupPartCAllPlan]
    (
      [EstRecevDetailBuildupPartCAllPlanID][INT] IDENTITY(1, 1)
                                           NOT NULL ,
      [HICN] [VARCHAR](15) NULL ,
      [Factor] [FLOAT] NULL ,
      [HCC] [VARCHAR](25) NULL ,
      [AgeGrpID] [VARCHAR](10) NULL ,
      [PaymentYear] [VARCHAR](4) NULL ,
      [MYUFlag] [VARCHAR](1) NULL ,
      [Populated] [SMALLDATETIME] NULL ,
      [HCCHierarchy] [VARCHAR](25) NULL ,
      [FactorHierarchy] [FLOAT] NULL ,
      [HCCDeleteHierarchy] [VARCHAR](25) NULL ,
      [FactorDeleteHierarchy] [FLOAT] NULL ,
      [RAFactorType] [VARCHAR](2) NULL ,
      [ModelYear] [INT] NULL ,
      [PlanIdentifier] [SMALLINT] NULL ,
      [HPLanID] [VARCHAR](5) NULL
    )