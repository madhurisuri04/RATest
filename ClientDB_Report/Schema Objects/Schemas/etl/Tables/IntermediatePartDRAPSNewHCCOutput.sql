CREATE TABLE [etl].[IntermediatePartDRAPSNewHCCOutput]
(
	    [IntermediatePartDRAPSNewHCCOutputId] [INT] IDENTITY(1,1) NOT NULL
	  , [PaymentYear] int null
      , [PaymStart] datetime null
      , [ModelYear] int null
      , [ProcessedByStart] datetime null
      , [ProcessedByEnd] datetime null
      , [PlanId] varchar(5) null
      , [HICN] varchar(15) null
      , [RAFactorType] char(2) null
      , [RAFactorTypeORIG] char(2) null
      , [ProcessedPriorityProcessedBy] datetime null
      , [ProcessedPriorityThruDate] datetime null
      , [ProcessedPriorityPCN] varchar(50) null
      , [HierHCCProcessedPCN] varchar(50) null
      , [ProcessedPriorityDiag] varchar(20) null
      , [ProcessedPriorityFileID] varchar(18) null
      , [ProcessedPriorityRAPSSourceID] varchar(50) null
      , [ProcessedPriorityRAC] char(1) null
      , [ThruPriorityProcessedBy] datetime null
      , [ThruPriorityThruDate] datetime null
      , [ThruPriorityPCN] varchar(50) null
      , [ThruPriorityDiag] varchar(20) null
      , [ThruPriorityFileID] varchar(18) null
      , [ThruPriorityRAPSSourceID] varchar(50) null
      , [ThruPriorityRAC] char(1) null
      , [HCC] varchar(50) null
      , [HCCOrig] varchar(50) null
      , [OnlyHCC] varchar(20) null
      , [HCCNumber] int null
      , [HCCDescription] varchar(255) null
      , [Factor] decimal(20, 4) null
      , [FactorDiff] decimal(20, 4) null
      , [FinalFactor] decimal(20, 4) null
      , [UnqCondition] int null
      , [HierHCCOld] varchar(20) null
      , [HierFactorOld] decimal(20, 4) null
      , [MemberMonths] int null
      , [ActiveIndicatorForRollforward] char(1) null
      , [MonthsInDCP] int null
      , [ESRD] char(1) null
      , [Hosp] char(1) null
      , [PBP] varchar(3) null
      , [SCC] varchar(5) null
      , [Bid] money null
      , [EstimatedValue] money null
      , [ProviderID] varchar(40) null
      , [ProviderLast] varchar(55) null
      , [ProviderFirst] varchar(55) null
      , [ProviderGroup] varchar(80) null
      , [ProviderAddress] varchar(100) null
      , [ProviderCity] varchar(30) null
      , [ProviderState] char(2) null
      , [ProviderZip] varchar(13) null
      , [ProviderPhone] varchar(15) null
      , [ProviderFax] varchar(15) null
      , [TaxID] varchar(55) null
      , [NPI] varchar(20) null
      , [MinProcessBySeqnum] int null
      , [UnionQueryInd] int null
      , [HCCPCNMatch] int null
      , [HIERPCNMatch] int null
      , [PaymStartYear] int null
      , [Aged] int
);
