CREATE TABLE [rev].[tbl_Summary_RskAdj_Log]
    (
     [tbl_Summary_RskAdj_LogId] [INT] IDENTITY(1, 1)
                                      NOT NULL
   , [SchemaName] [VARCHAR](130) NOT NULL
   , [ProcessName] [VARCHAR](130) NOT NULL
   , [CurrentStatus] [VARCHAR](32) NULL
   , [ActiveBDate] [DATE] NOT NULL
   , [ActiveEDate] [DATE] NULL
   , [LastRun] [DATETIME] NULL
   , [LastRunBy] [VARCHAR](257) NULL
    ) 

	