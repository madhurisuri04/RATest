CREATE TABLE [rev].[EDS_DiagHCC_rollup] (
    [EDS_DiagHCC_rollupID] [BIGINT] IDENTITY(1, 1) NOT NULL
  , [PlanIdentifier] [SMALLINT] NOT NULL
  , [EDSID] [INT] NOT NULL 
  , [ProcessedBy] [SMALLDATETIME] NOT NULL
  , [CorrectedHICN] [VARCHAR](25) NULL
  , [Descr] [VARCHAR](255) NULL
  , [DiagnosisCode] [VARCHAR](7) NULL
  , [DiagnosisError1] [VARCHAR](3) NULL
  , [DiagnosisError2] [VARCHAR](3) NULL
  , [DOB] [DATETIME] NULL
  , [DOBError] [VARCHAR](3) NULL
  , [FileID] [VARCHAR](18) NULL
  , [Filler] [VARCHAR](75) NULL
  , [FromDate] [SMALLDATETIME] NULL
  , [HICN] [VARCHAR](25) NULL
  , [HICNError] [VARCHAR](3) NULL
  , [PatientControlNumber] [VARCHAR](40) NULL
  , [ProviderType] [VARCHAR](2) NULL
  , [SeqError] [VARCHAR](7) NULL
  , [SeqNumber] [VARCHAR](7) NULL
  , [ThruDate] [SMALLDATETIME] NULL
  , [Void_Indicator] [BIT] NULL
  , [Voided_by_EDSID] [INT] NULL
  , [PartC_HCC] [VARCHAR](50) NULL
  , [PartD_HCC] [VARCHAR](50) NULL
  , [Accepted] [BIT] NULL
  , [Deleted] [VARCHAR](1) NULL
  , [Source_Id] [INT] NULL
  , [Provider_Id] [VARCHAR](40) NULL
  , [RAC] [VARCHAR](1) NULL
  , [RAC_Error] [VARCHAR](3) NULL)