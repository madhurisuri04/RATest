CREATE TABLE [dbo].[EdgeReportClientStatus](
	[EdgeReportClientStatusID] [int] IDENTITY(1,1) NOT NULL,
	[OrganizationID] int not null,
	[ReportType] [varchar](30) not NULL,
	[EnableFlag] [bit] not null
) ON [PRIMARY]