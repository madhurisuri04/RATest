CREATE TABLE [etl].[tbl_Intermediate_RskAdj_RAPS_Preliminary]
    (
     [RAPS_PreliminaryId] [BIGINT] IDENTITY(1, 1) NOT NULL
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
   , [SeqNumber] [VARCHAR](7) NULL
   , [ThruDate] [SMALLDATETIME] NULL
   , [Deleted] [CHAR](1) NULL
   , [Source_Id] [INT] NULL
   , [Provider_Id] [VARCHAR](40) NULL
   , [RAC] [CHAR](1) NULL
   , [HCC_Label] [NVARCHAR](255) NULL
   , [HCC_Number] [INT] NULL
   , [Aged] [INT] NULL
    );



