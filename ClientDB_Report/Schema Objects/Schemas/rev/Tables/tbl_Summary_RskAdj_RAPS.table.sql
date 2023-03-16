CREATE TABLE [rev].[tbl_Summary_RskAdj_RAPS]
    (
     [tbl_Summary_RskAdj_RAPSId] [BIGINT] IDENTITY(1, 1)
                                          NOT NULL
   , [PlanID] [INT] NULL
   , [HICN] [VARCHAR](12) NULL
   , [PaymentYear] [INT] NOT NULL
   , [PaymStart] [DATETIME] NULL
   , [ModelYear] [INT] NULL
   , [Factor_category] [VARCHAR](20) NULL
   , [Factor_Desc] [VARCHAR](50) NULL
   , [Factor] [DECIMAL](20, 4) NULL
   , [RAFT] [CHAR](3) NULL
   , [HCC_Number] [INT] NULL
   , [Min_ProcessBy] [DATETIME] NULL
   , [Min_ThruDate] [DATETIME] NULL
   , [Min_ProcessBy_SeqNum] [INT] NULL
   , [Min_ThruDate_SeqNum] [INT] NULL
   , [Min_Processby_DiagCD] [VARCHAR](7) NULL
   , [Min_ThruDate_DiagCD] [VARCHAR](7) NULL
   , [Min_ProcessBy_PCN] [VARCHAR](40) NULL
   , [Min_ThruDate_PCN] [VARCHAR](40) NULL
   , [Processed_Priority_Thru_Date] [DATETIME] NULL
   , [Thru_Priority_Processed_By] [DATETIME] NULL
   , [RAFT_ORIG] [CHAR](2) NULL
   , [Processed_Priority_FileID] [VARCHAR](18) NULL
   , [Processed_Priority_RAPS_Source_ID] [INT] NULL
   , [Processed_Priority_Provider_ID] [VARCHAR](40) NULL
   , [Processed_Priority_RAC] [CHAR](1) NULL
   , [Thru_Priority_FileID] [VARCHAR](18) NULL
   , [Thru_Priority_RAPS_Source_ID] [INT] NULL
   , [Thru_Priority_Provider_ID] [VARCHAR](40) NULL
   , [Thru_Priority_RAC] [CHAR](1) NULL
   , [IMFFlag] [SMALLINT] NULL
   , [Factor_Desc_ORIG] [VARCHAR](50) NULL
   , [LoadDateTime] [DATETIME] NOT NULL
   ,[Aged] [int] NULL
    )


