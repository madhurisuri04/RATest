CREATE TABLE [rev].[tbl_Summary_RskAdj_EDS] 
(
    [ID] [BIGINT] IDENTITY(1, 1) NOT NULL
  , [PlanID] [INT] NULL
  , [HICN] [VARCHAR](12) NULL
  , [PaymentYear] [INT] NULL
  , [PaymStart] [DATETIME] NULL
  , [Model_Year] [INT] NULL
  , [Factor_category] [VARCHAR](20) NULL
  , [Factor_Desc] [VARCHAR](50) NULL
  , [Factor] [DECIMAL](20, 4) NULL
  , [RAFT] [VARCHAR](3) NULL
  , [HCC_Number] [INT] NULL
  , [Min_ProcessBy] [DATETIME] NULL
  , [Min_ThruDate] [DATETIME] NULL
  , [Min_ProcessBy_SeqNum] [INT] NULL
  , [Min_ThruDate_SeqNum] [INT] NULL
  , [Min_Processby_DiagCD] [VARCHAR](7) NULL
  , [Min_ThruDate_DiagCD] [VARCHAR](7) NULL
  , [Min_ProcessBy_PCN] [VARCHAR](40) NULL
  , [Min_ThruDate_PCN] [VARCHAR](40) NULL
  , [processed_priority_thru_date] [DATETIME] NULL
  , [thru_priority_processed_by] [DATETIME] NULL
  , [RAFT_ORIG] [VARCHAR](2) NULL
  , [Processed_Priority_FileID] [VARCHAR](18) NULL
  , [Processed_Priority_RAPS_Source_ID] [INT] NULL
  , [Processed_Priority_Provider_ID] [VARCHAR](40) NULL
  , [Processed_Priority_RAC] [VARCHAR](1) NULL
  , [Thru_Priority_FileID] [VARCHAR](18) NULL
  , [Thru_Priority_RAPS_Source_ID] [INT] NULL
  , [Thru_Priority_Provider_ID] [VARCHAR](40) NULL
  , [Thru_Priority_RAC] [VARCHAR](1) NULL
  , [IMFFlag] [SMALLINT] NULL
  , [Factor_Desc_ORIG] [VARCHAR](50) NULL
  , [Factor_Desc_EstRecev] [VARCHAR](50) NULL
  , [LoadDateTime] [DATETIME] NULL
  , Min_ProcessBy_MAO004ResponseDiagnosisCodeId BIGINT NULL
  , Min_ThruDate_MAO004ResponseDiagnosisCodeId BIGINT NULL
  , Aged INT NULL,
  [LastAssignedHICN] VARCHAR(12) NULL
  )