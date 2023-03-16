CREATE TABLE [rev].[tbl_Summary_RskAdj_AltHICN]
    (
     [tbl_Summary_RskAdj_AltHICNId] [BIGINT] IDENTITY(1, 1) NOT NULL
   , [PlanID] [INT] NULL
   , [HICN] [VARCHAR](12) NULL
   , [FINALHICN] [VARCHAR](12) NULL
   , [LoadDateTime] [DATETIME] NULL
   , [LastAssignedHICN] [VARCHAR](12) NULL
   , [LastUpdatedInSource] [DATETIME] NULL
   , [UserID] [VARCHAR](128) NULL
    )
	