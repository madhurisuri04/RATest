CREATE TABLE [rev].[EDSNewHCCPartC] (
    [EDSNewHCCPartCId] [BIGINT] IDENTITY(1, 1) NOT NULL
  , [ProcessRunId] [INT] NULL
  , [PlanId] [CHAR](5) NULL
  , [Payment_Year] [INT] NULL
  , [Model_Year] [INT] NULL
  , [Processed_By_Start] [DATETIME] NULL
  , [Processed_By_End] [DATETIME] NULL
  , [HICN] [VARCHAR](15) NULL
  , [Ra_Factor_Type] [CHAR](2) NULL
  , [Processed_By_Flag] [CHAR](1) NULL
  , [HCC] [VARCHAR](50) NULL
  , [HCC_Description] [VARCHAR](255) NULL
  , [HCC_FACTOR] [DECIMAL](20, 4) NULL
  , [HIER_HCC] [VARCHAR](24) NULL
  , [HIER_HCC_FACTOR] [DECIMAL](20, 4) NULL
  , [Pre_Adjstd_Factor] [DECIMAL](20, 4) NULL
  , [Adjstd_Final_Factor] [DECIMAL](20, 4) NULL
  , [HCC_PROCESSED_PCN] [VARCHAR](50) NULL
  , [HIER_HCC_PROCESSED_PCN] [VARCHAR](50) NULL
  , [UNQ_CONDITIONS] [BIT] NOT NULL
  , [Months_In_DCP] [INT] NULL
  , [Member_Months] [INT] NULL
  , [Bid_Amount] [MONEY] NULL
  , [Estimated_Value] [MONEY] NULL
  , [Rollforward_Months] [INT] NULL
  , [Annualized_Estimated_Value] [MONEY] NULL
  , [PBP] [CHAR](3) NULL
  , [SCC] [CHAR](5) NULL
  , [Processed_Priority_Processed_By] [DATETIME] NULL
  , [Processed_Priority_Thru_Date] [DATETIME] NULL
  , [Processed_Priority_Diag] [VARCHAR](20) NULL
  , [Processed_Priority_FileID] [VARCHAR](18) NULL
  , [Processed_Priority_RAC] [CHAR](1) NULL
  , [Processed_Priority_RAPS_Source_ID] [VARCHAR](50) NULL
  , [DOS_Priority_Processed_By] [DATETIME] NULL
  , [DOS_Priority_Thru_Date] [DATETIME] NULL
  , [DOS_Priority_PCN] [VARCHAR](50) NULL
  , [DOS_Priority_Diag] [VARCHAR](20) NULL
  , [DOS_Priority_FileId] [VARCHAR](18) NULL
  , [DOS_Priority_RAC] [CHAR](1) NULL
  , [DOS_PRIORITY_RAPS_SOURCE] [VARCHAR](50) NULL
  , [Provider_Id] [VARCHAR](40) NULL
  , [Provider_Last] [VARCHAR](55) NULL
  , [Provider_First] [VARCHAR](55) NULL
  , [Provider_Group] [VARCHAR](80) NULL
  , [Provider_Address] [VARCHAR](100) NULL
  , [Provider_City] [VARCHAR](30) NULL
  , [Provider_State] [CHAR](2) NULL
  , [Provider_Zip] [VARCHAR](13) NULL
  , [Provider_Phone] [VARCHAR](15) NULL
  , [Provider_Fax] [VARCHAR](15) NULL
  , [Tax_Id] [VARCHAR](55) NULL
  , [NPI] [VARCHAR](20) NULL
  , [Sweep_Date] [DATE] NULL
  , [Populated_Date] [DATETIME] NULL
  , [PCN_SubprojectId] [VARCHAR](32) NULL
  , [PCN_Coding_Entity] [VARCHAR](32) NULL
  , [PCN_ProviderId] [VARCHAR](32) NULL
  , [FailureReason] [VARCHAR](20) NULL
  )