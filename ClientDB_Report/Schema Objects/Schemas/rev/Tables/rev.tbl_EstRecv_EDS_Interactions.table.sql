CREATE TABLE [rev].[tbl_EstRecv_EDS_Interactions] (
    [PlanID] [INT] NULL
  , [HICN] [VARCHAR](12) NOT NULL
  , [RAFT] [VARCHAR](3) NOT NULL
  , [HCC] [VARCHAR](50) NOT NULL
  , [HCC_Number] [INT] NULL
  , [HCC_Number1] [INT] NULL
  , [HCC_Number2] [INT] NULL
  , [HCC_Number3] [INT] NULL
  , [Min_Process_By] [DATETIME] NULL
  , [Min_Thru] [DATETIME] NULL
  , [Min_ProcessBy_SeqNum] [INT] NULL
  , [Min_Thru_SeqNum] [INT] NULL
  , [Min_Processby_DiagID] [INT] NULL
  , [Min_ThruDate_DiagID] [INT] NULL
  , [Min_Processby_DiagCD] [VARCHAR](7) NULL
  , [Min_ThruDate_DiagCD] [VARCHAR](7) NULL
  , [Min_ProcessBy_PCN] [VARCHAR](40) NULL
  , [Min_ThruDate_PCN] [VARCHAR](40) NULL
  , [processed_priority_thru_date] [DATETIME] NULL
  , [thru_priority_processed_by] [DATETIME] NULL
  , [Payment_Year] [INT] NULL
  , [Processed_Priority_FileID] [VARCHAR](18) NULL
  , [Processed_Priority_RAPS_Source_ID] [INT] NULL
  , [Processed_Priority_Provider_ID] [VARCHAR](40) NULL
  , [Processed_Priority_RAC] [VARCHAR](1) NULL
  , [Thru_Priority_FileID] [VARCHAR](18) NULL
  , [Thru_Priority_RAPS_Source_ID] [INT] NULL
  , [Thru_Priority_Provider_ID] [VARCHAR](40) NULL
  , [Thru_Priority_RAC] [VARCHAR](1) NULL
  , [IMFFlag] [SMALLINT] NULL
  , [HCC_ORIG] [VARCHAR](50) NULL
  , [HCC_ORIG_EstRecev] [VARCHAR](50) NULL
  , [Max_HCC_NumberMPD] [INT] NULL
  , [Max_HCC_NumberMTD] [INT] NULL)