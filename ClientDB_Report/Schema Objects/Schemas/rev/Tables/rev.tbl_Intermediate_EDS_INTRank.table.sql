CREATE TABLE [rev].[tbl_Intermediate_EDS_INTRank] (
    [tbl_Intermediate_EDS_INTRankId] [BIGINT] IDENTITY(1, 1) NOT NULL
  , [PaymentYear] [INT] NULL
  , [ModelYear] [INT] NULL
  , [HICN] [VARCHAR](12) NULL
  , [RAFT] [CHAR](3) NULL
  , [HCC] [VARCHAR](50) NULL
  , [Min_ProcessBy_SeqNum] [INT] NULL
  , [Min_Thru_SeqNum] [INT] NULL
  , [Min_Processby_DiagCD] [VARCHAR](7) NULL
  , [Min_ThruDate_DiagCD] [VARCHAR](7) NULL
  , [RankID] [INT] NULL
  , [LoadDateTime] [DATETIME] NOT NULL)
