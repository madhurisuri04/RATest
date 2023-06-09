CREATE TABLE etl.SummaryPartDRskAdjRAPSMORDCombined
    (
      [SummaryPartDRskAdjRAPSMORDCombinedID] BIGINT IDENTITY(1, 1)
                                                    NOT NULL ,
      [PaymentYear] INT NOT NULL ,
      [PlanIdentifier] INT NULL ,
      [HICN] VARCHAR(12) NULL ,
      [PaymStart] DATETIME NULL ,
      [ModelYear] INT NULL ,
      [FactorCategory] VARCHAR(20) NULL ,
      [ESRD] CHAR(2) NULL ,
      [Hospice] CHAR(2) NULL ,
      [RxHCCLabel] VARCHAR(50) NULL ,
      [Factor] DECIMAL(20, 4) NULL ,
      [PartDRAFTRestated] CHAR(3) NULL ,
      [RxHCCNumber] INT NULL ,
      [MinProcessBy] DATETIME NULL ,
      [MinThruDate] DATETIME NULL ,
      [MinProcessBySeqNum] INT NULL ,
      [MinThruDateSeqNum] INT NULL ,
      [MinProcessbyDiagCD] VARCHAR(7) NULL ,
      [MinThruDateDiagCD] VARCHAR(7) NULL ,
      [MinProcessByPCN] VARCHAR(40) NULL ,
      [MinThruDatePCN] VARCHAR(40) NULL ,
      [ProcessedPriorityThruDate] DATETIME NULL ,
      [ThruPriorityProcessedBy] DATETIME NULL ,
      [ProcessedPriorityFileID] VARCHAR(18) NULL ,
      [ProcessedPriorityRAPSSourceID] INT NULL ,
      [ProcessedPriorityProviderID] VARCHAR(40) NULL ,
      [ProcessedPriorityRAC] CHAR(1) NULL ,
      [ThruPriorityFileID] VARCHAR(18) NULL ,
      [ThruPriorityRAPSSourceID] INT NULL ,
      [ThruPriorityProviderID] VARCHAR(40) NULL ,
      [ThruPriorityRAC] CHAR(1) NULL ,
      [IMFFlag] SMALLINT NULL ,
      [RxHCCLabelOrig] VARCHAR(50) NULL ,
      [PartDRAFTMMR] CHAR(2) NULL ,
      [Aged] INT NULL ,
      [LoadDate] DATETIME NOT NULL ,
      [UserID] VARCHAR(128) NOT NULL,
	  [LastAssignedHICN] VARCHAR(12) NULL
    )
ON  [pscheme_SummPY](PaymentYear) 


