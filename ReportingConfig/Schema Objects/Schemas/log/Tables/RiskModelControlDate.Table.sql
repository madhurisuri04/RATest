CREATE TABLE [log].[RiskModelControlDate](
[RiskModelControlDateId] [int] IDENTITY(1,1) NOT NULL,
[RiskModelId] [Int] NOT NULL, 
[RiskModelYear] [smallint] NOT NULL,
[StartDOS] AS CONVERT(DATETIME2, CONVERT(VARCHAR(5),RiskModelYear)+ '-01-01 00:00:00.0000000'),
[EndDOS] AS CONVERT(DATETIME2, CONVERT(VARCHAR(5),RiskModelYear)+ '-12-31 23:59:59.9999999'),
[StartClaimReceivedDate] [datetime2] NOT NULL,
[EndClaimReceivedDate] [datetime2] NOT NULL,
[RiskScoreFreezeDate] [datetime2] NOT NULL,
[DaysActiveAfterFreezeDate] [smallint] NOT NULL,
[RiskScoreAsOfDate] [varchar](50) NOT NULL,
[CreateDateTime] [datetime2](7) NOT NULL,
[UpdateDateTime] [datetime2](7) NOT NULL,
[CreateLoadid] [int] NOT NULL,
[UpdateLoadId] [int] NOT NULL,
[CreateUserId] [varchar](30) NOT NULL,
[UpdateUserId] [varchar](30) NOT NULL
)
;