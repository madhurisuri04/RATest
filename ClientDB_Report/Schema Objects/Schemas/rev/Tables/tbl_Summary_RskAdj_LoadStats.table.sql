CREATE TABLE [rev].[tbl_Summary_RskAdj_LoadStats](
	[tbl_Summary_RskAdj_LoadStatsId] [INT] IDENTITY(1, 1)
                                            NOT NULL
   , [ServerName] [VARCHAR](128) NULL
   , [DbName] [VARCHAR](128) NULL
   , [TableName] [VARCHAR](128) NOT NULL
   , [PaymentYear] [INT] NULL
   , [Model_Year] [INT] NULL
   , [LoadDateTime] [DATETIME] NULL
   , [Count] [INT] NULL
   , [CaptureDateTime] [DATETIME] NOT NULL
   , [RunBy] [VARCHAR](257) NULL
)