CREATE TABLE [etl].[lk_CohortTagDescription](
	[CohortTagId] [int] IDENTITY(1, 1) NOT NULL
	,[CohortTag] [varchar](50) NULL
	,[PlanFamilyCode] [varchar](50) NULL
	,[PlanFamilyDesc] [varchar](50) NULL
	,[MemberTypeCode] [varchar](50) NULL
	,[MemberTypeDesc] [varchar](50) NULL
	,[PlanYearCode] [varchar](50) NULL
	,[PlanYearDesc] [varchar](50) NULL
	,[CFORegionCode] [varchar](50) NULL
	,[CFORegionDesc] [varchar](50) NULL
	,[CFOSubSegmentCode] [varchar](50) NULL
	,[CFOSubSegmentDesc] [varchar](50) NULL
	,[CohortIDCode] [varchar](50) NULL
	,[CohortIDDesc] [varchar](100) NULL
	,[FileName] [varchar](255) NULL
	,[ServiceAreaDescription] [varchar](80) NULL
	,[LocalMarketCode] [varchar](12) NULL
	,[LocalMarketDescription] [varchar](50) NULL
	,[CFOSubsegmentDescription] [varchar](80) NULL
	,[Populated] [datetime] NULL
	,[LoadID] BIGINT NULL
	,[LoadDate] [datetime] NULL
	);