CREATE TABLE [dbo].[EdgeReportConfiguration](
	[EdgeReportConfigurationID] [int] IDENTITY(1,1) NOT NULL,
	[ConfigurationDefinition] [varchar](30) NULL,
	[ConfigurationValue] [varchar](255) NULL,
	[ReportType] [varchar](30) NULL
) ON [PRIMARY]