CREATE TABLE [log].[ReportingLogControl](
[ReportingLogControlId] [int] IDENTITY(1,1) NOT NULL,
[OrganizationID] [int] NOT NULL,
[ApplicationCode] [varchar](30) NOT NULL,
[ProcessCode] [varchar](12) NOT NULL,
[Category] [varchar](10)  NULL,
[LastSuccessfulDepotPullDate] [datetime2](7) NULL,
[RunDate] [datetime2](7) NOT NULL,
[RunStatus] [varchar](30) NULL
) ON [PRIMARY]
