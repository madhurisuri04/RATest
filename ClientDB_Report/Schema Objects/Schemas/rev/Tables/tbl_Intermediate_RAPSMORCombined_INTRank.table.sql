CREATE TABLE [rev].[tbl_Intermediate_RAPSMORCombined_INTRank]
    (
     [tbl_Intermediate_RAPSMORCombined_INTRankId] INT IDENTITY(1, 1)
                                                      NOT NULL
   , [PaymentYear] INT
   , [ModelYear] INT
   , [HICN] VARCHAR(12)
   , [RAFT] CHAR(3)
   , [HCC] VARCHAR(50)
   , [Min_ProcessBy_SeqNum] INT
   , [Min_Thru_SeqNum] INT
   , [Min_Processby_DiagCD] VARCHAR(7)
   , [Min_ThruDate_DiagCD] VARCHAR(7)
   , [RankID] INT
   , [LoadDateTime] DATETIME NOT NULL
    )
