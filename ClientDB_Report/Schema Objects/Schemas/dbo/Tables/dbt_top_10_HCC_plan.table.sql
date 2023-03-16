CREATE TABLE [dbo].[dbt_top_10_HCC_plan] (
    [ReportType]                  VARCHAR (20)    NULL,
    [Plan_ID]                     VARCHAR (5)     NULL,
    [Payment_Year]                VARCHAR (4)     NULL,
    [Category]                    VARCHAR (10)    NULL,
    [DESCRIPTION]                 VARCHAR (255)   NULL,
    [Community_Factor]            FLOAT           NULL,
    [Norm_Factor]                 DECIMAL (18, 4) NULL,
    [Community_Factor_Normalized] FLOAT           NULL,
    [Count_Members]               INT             NULL,
    [Avg_Bid_C]                   MONEY           NULL,
    [Avg_Bid_D]                   MONEY           NULL,
    [PMPM]                        MONEY           NULL,
    [Est_Impact]                  MONEY           NULL,
    [populated]                   SMALLDATETIME   NULL
);

