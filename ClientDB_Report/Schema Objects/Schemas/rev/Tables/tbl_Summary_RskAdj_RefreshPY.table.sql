CREATE TABLE [rev].[tbl_Summary_RskAdj_RefreshPY]
    (
     [tbl_Summary_RskAdj_RefreshPYId] INT IDENTITY(1, 1)
   , [Payment_Year] INT
   , [From_Date] DATE
   , [Thru_Date] DATE
   , [Lagged_From_Date] DATE
   , [Lagged_Thru_Date] DATE
   , [Initial_Sweep_Date] DATE
   , [Final_Sweep_Date] DATE
   , [MidYear_Sweep_Date] DATE
   , [LoadDateTime] [DATETIME] NOT NULL
    )
