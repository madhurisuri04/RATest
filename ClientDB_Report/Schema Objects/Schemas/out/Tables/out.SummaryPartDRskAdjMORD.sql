CREATE TABLE out.SummaryPartDRskAdjMORD
    (
      [SummaryRskAdjMORDId] BIGINT IDENTITY(1, 1)
                                NOT NULL ,
      [PaymentYear] INT NOT NULL ,
      [PlanIdentifier] INT NULL ,
      [HICN] VARCHAR(12) NULL ,
      [PaymStart] DATE NULL ,
      [ModelYear] INT NULL ,
      [FactorCategory] VARCHAR(20) NULL ,
      [RxHCCLabel] VARCHAR(50) NULL ,
      [Factor] DECIMAL(20, 4) NULL ,
      [RxHCCNumber] VARCHAR(5) NULL ,
      [PartDRAFT] CHAR(3) NULL ,
      [PartDRAFTMMR] CHAR(2) NULL ,
      [RecordType] CHAR(2) NULL ,
      [HOSP] CHAR(1) NULL ,
      [ORECCalc] VARCHAR(5) NULL ,
      [Aged] INT NULL ,
      [LoadDate] DATETIME NOT NULL ,
      [UserID] VARCHAR(128) NOT NULL
    )
ON  pscheme_SummPY(PaymentYear) 

