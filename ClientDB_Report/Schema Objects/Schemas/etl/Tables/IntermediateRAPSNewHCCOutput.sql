﻿CREATE TABLE [etl].[IntermediateRAPSNewHCCOutput]
(
    [IntermediateRAPSNewHCCOutputId] [BIGINT] IDENTITY(1, 1) NOT NULL,
    [PaymentYear] [INT] NULL,
    [PaymStart] [DATETIME] NULL,
    [ModelYear] [INT] NULL,
    [ProcessedByStart] [DATETIME] NULL,
    [PlanID] [INT] NULL,
    [HICN] [VARCHAR](15) NULL,
    [RAFactorType] [VARCHAR](2) NULL,
    [RAFactorTypeORIG] [VARCHAR](2) NULL,
    [ProcessedPriorityProcessedBy] [DATETIME] NULL,
    [ProcessedPriorityThruDate] [DATETIME] NULL,
    [ProcessedPriorityPCN] [VARCHAR](50) NULL,
    [ProcessedPriorityDiag] [VARCHAR](20) NULL,
    [ProcessedPriorityFileID] [VARCHAR](18) NULL,
    [ProcessedPriorityRAPSSourceID] [VARCHAR](50) NULL,
    [ProcessedPriorityRAC] [VARCHAR](1) NULL,
    [ThruPriorityProcessedBy] [DATETIME] NULL,
    [ThruPriorityThruDate] [DATETIME] NULL,
    [ThruPriorityPCN] [VARCHAR](50) NULL,
    [ThruPriorityDiag] [VARCHAR](20) NULL,
    [ThruPriorityFileID] [VARCHAR](18) NULL,
    [ThruPriorityRAPSSourceID] [VARCHAR](50) NULL,
    [ThruPriorityRAC] [VARCHAR](1) NULL,
    [HCC] [VARCHAR](50) NULL,
    [HCCOrig] [VARCHAR](50) NULL,
    [OnlyHCC] [VARCHAR](20) NULL,
    [HCCNumber] [INT] NULL,
    [HCCDescription] [VARCHAR](255) NULL,
    [Factor] [DECIMAL](20, 4) NULL,
    [FactorDiff] [DECIMAL](20, 4) NULL,
    [FinalFactor] [DECIMAL](20, 4) NULL,
    [UnqCondition] [INT] NULL,
    [HierFactorOld] [DECIMAL](20, 4) NULL,
    [MemberMonths] [INT] NULL,
    [ActiveIndicatorForRollforward] [VARCHAR](1) NULL,
    [MonthsInDCP] [INT] NULL,
    [ESRD] [VARCHAR](1) NULL,
    [HOSP] [VARCHAR](1) NULL,
    [PBP] [VARCHAR](3) NULL,
    [SCC] [VARCHAR](5) NULL,
    [BID] [MONEY] NULL,
    [EstimatedValue] [MONEY] NULL,
    [ProviderID] [VARCHAR](40) NULL,
    [ProviderLast] [VARCHAR](55) NULL,
    [ProviderFirst] [VARCHAR](55) NULL,
    [ProviderGroup] [VARCHAR](80) NULL,
    [ProviderAddress] [VARCHAR](100) NULL,
    [ProviderCity] [VARCHAR](30) NULL,
    [ProviderZip] [VARCHAR](13) NULL,
    [ProviderPhone] [VARCHAR](15) NULL,
    [ProviderFax] [VARCHAR](15) NULL,
    [TaxID] [VARCHAR](55) NULL,
    [NPI] [VARCHAR](20) NULL,
    [MinProcessBySeqnum] [INT] NULL,
    [Unionqueryind] [INT] NULL,
    [HCCPCNMatch] [INT] NULL,
    [HierPCNMatch] [INT] NULL,
    [PaymStartYear] [INT] NULL,
    [AGED] [INT] NULL,
    [ProcessedByEnd] [DATETIME] NULL,
    [HierHCCProcessedPCN] [VARCHAR](50) NULL,
    [HierHCCOld] [VARCHAR](20) NULL,
    [ProviderState] [VARCHAR](2) NULL
);
