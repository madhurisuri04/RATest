CREATE TABLE [rev].[tbl_Intermediate_RAPSMORCombined]
    (
     [tbl_Intermediate_RAPSMORCombinedId] BIGINT IDENTITY(1, 1)
   , [PaymentYear] [INT] NULL
   , [ModelYear] [INT] NULL
   , [PlanID] [INT] NULL
   , [HICN] [VARCHAR](12) NULL
   , [RAFT] [CHAR](3) NULL
   , [HCC] [VARCHAR](50) NULL
   , [HCC_Number] [INT] NULL
   , [Min_Process_By] [DATETIME] NULL
   , [Min_Thru] [DATETIME] NULL
   , [Min_ProcessBy_SeqNum] [INT] NULL
   , [Min_Thru_SeqNum] [INT] NULL
   , [Deleted] [CHAR](1) NULL
   , [Min_Processby_DiagID] [INT] NULL
   , [Min_ThruDate_DiagID] [INT] NULL
   , [Min_Processby_DiagCD] [VARCHAR](7) NULL
   , [Min_ThruDate_DiagCD] [VARCHAR](7) NULL
   , [Min_ProcessBy_PCN] [VARCHAR](40) NULL
   , [Min_ThruDate_PCN] [VARCHAR](40) NULL
   , [Processed_Priority_Thru_Date] [DATETIME] NULL
   , [Thru_Priority_Processed_By] [DATETIME] NULL
   , [Processed_Priority_FileID] [VARCHAR](18) NULL
   , [Processed_Priority_RAPS_Source_ID] [INT] NULL
   , [Processed_Priority_Provider_ID] [VARCHAR](40) NULL
   , [Processed_Priority_RAC] [CHAR](1) NULL		---Was varchar(1)
   , [Thru_Priority_FileID] [VARCHAR](18) NULL
   , [Thru_Priority_RAPS_Source_ID] [INT] NULL
   , [Thru_Priority_Provider_ID] [VARCHAR](40) NULL
   , [Thru_Priority_RAC] [CHAR](1) NULL		--Was varchar(1)
   , [IMFFlag] [SMALLINT] NULL
   , [HCC_ORIG] [VARCHAR](50) NULL
   , [LoadDateTime] DATETIME NOT NULL
    ) 
