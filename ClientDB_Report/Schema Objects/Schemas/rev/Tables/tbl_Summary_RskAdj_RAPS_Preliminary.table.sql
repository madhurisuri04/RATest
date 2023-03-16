CREATE TABLE [rev].[tbl_Summary_RskAdj_RAPS_Preliminary]
    (
     [tbl_Summary_RskAdj_RAPS_PreliminaryId] [BIGINT] IDENTITY(1, 1)
                                                      NOT NULL
   , [PlanIdentifier] [INT] NULL
   , [PaymentYear] [INT] NULL
   , [ModelYear] [INT] NULL
   , [HICN] [VARCHAR](12) NULL
   , [PartCRAFTProjected] [CHAR](2) NULL
   , [RAPS_DiagHCC_rollupID] [INT] NOT NULL
   , [RAPSID] [INT] NOT NULL
   , [ProcessedBy] [SMALLDATETIME] NOT NULL
   , [DiagnosisCode] [VARCHAR](7) NULL
   , [FileID] [VARCHAR](18) NULL
   , [FromDate] [SMALLDATETIME] NULL
   , [PatientControlNumber] [VARCHAR](40) NULL
   , [ProviderType] [CHAR](2) NULL
   , [SeqNumber] [VARCHAR](7) NULL
   , [ThruDate] [SMALLDATETIME] NULL
   , [Void_Indicator] [BIT] NULL
   , [Voided_by_RAPSID] [INT] NULL
   , [Accepted] [BIT] NULL
   , [Deleted] [CHAR](1) NULL
   , [Source_Id] [INT] NULL
   , [Provider_Id] [VARCHAR](40) NULL
   , [RAC] [CHAR](1) NULL
   , [RAC_Error] [CHAR](3) NULL
   , [HCC_Label] [NVARCHAR](255) NULL
   , [HCC_Number] [INT] NULL
   , [LoadDateTime] [DATETIME] NOT NULL
   , [Aged] [INT] NULL
    ) 



