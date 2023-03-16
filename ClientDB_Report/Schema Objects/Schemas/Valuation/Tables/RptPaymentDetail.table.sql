CREATE TABLE Valuation.RptPaymentDetail
    (
     [RptPaymentDetailId] [INT] IDENTITY(1, 1)
                                NOT NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessRunId] [INT] NOT NULL
   , [ReportHeader] [VARCHAR](128) NOT NULL
   , [ReportType] [VARCHAR](128) NOT NULL
   , [ReportSubType] [VARCHAR](128) NOT NULL
   , [Header_A] [VARCHAR](128) NOT NULL
   , [Header_B] [VARCHAR](128) NOT NULL
   , [Header_ESRD] [VARCHAR](128) NOT NULL
   , [RowDisplay] [VARCHAR](128) NULL
   , [ChartsCompleted] [INT] NULL
   , [HCCTotal_A] [INT] NULL
   , [EstRev_A] [MONEY] NULL
   , [EstRevPerHCC_A] [MONEY] NULL
   , [HCCRealizationRate_A] [NUMERIC](34, 18) NULL
   , [HCCTotal_B] [INT] NULL
   , [EstRev_B] [MONEY] NULL
   , [EstRevPerHCC_B] [MONEY] NULL
   , [HCCRealizationRate_B] [NUMERIC](34, 18) NULL
   , [HCCTotal_ESRD] [INT] NULL
   , [EstRev_ESRD] [MONEY] NULL
   , [EstRevPerHCC_ESRD] [MONEY] NULL
   , [HCCRealizationRate_ESRD] [NUMERIC](34, 18) NULL
   , [ProjectId] [INT] NULL
   , [ProjectDescription] [VARCHAR](85) NULL
   , [SubProjectId] [INT] NULL
   , [SubProjectDescription] [VARCHAR](255) NULL
   , [ReviewName] [VARCHAR](50) NULL
   , [ProjectSortOrder] [SMALLINT] NULL
   , [SubProjectSortOrder] [SMALLINT] NULL
   , [OrderFlag] [SMALLINT] NOT NULL
   , [PopulatedDate] [DATETIME] NOT NULL
   , [HCCTotal_Non_ESRD] [int] NULL
   , [EstRev_Non_ESRD] [money] NULL
   , [EstRevPerHCC_Non_ESRD] [money] NULL
   , [HCCRealizationRate_Non_ESRD] [numeric](34, 18) NULL
   , [EsTRevPerChart_A] [money] NULL
   , [EsTRevPerChart_B] [money] NULL
   , [Part_C_D] [Varchar](4) NULL
    )