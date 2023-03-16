CREATE TABLE [rev].[EstRecvRskadjActivity]
    (
     [EstRecvRskadjActivityID] [INT] IDENTITY(1, 1) NOT NULL
   , [Part_C_D_Flag] VARCHAR(10) NULL
   , [Process] [VARCHAR](130) NULL
   , [Payment_Year] INT NULL
   , [MYU] VARCHAR(2)
   , [BDate] [DATETIME] NULL
   , [EDate] [DATETIME] NULL
   , [AdditionalRows] [INT] NULL
   , [RunBy] [VARCHAR](257) NULL
    )
	 