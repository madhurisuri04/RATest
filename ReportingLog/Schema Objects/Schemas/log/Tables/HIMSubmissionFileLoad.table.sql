CREATE TABLE [log].[HIMSubmissionFileLoad]
(
	[HIMSubmissionFileLoadID] [int] IDENTITY(1,1) NOT NULL,
	[OrganizationID] [int] NOT NULL,
	[FileName] [varchar](50) NOT NULL,
	[StartDateTime] [datetime2](7) NOT NULL,
	[EndDateTime] [datetime2](7) NULL,
	[DurationInMins] [smallint] NULL,
	[Status] [varchar](20) NOT NULL,
	[LoadID] [bigint] NOT NULL,
	[ErroredOnPackage] [varchar](50) NULL,
	[ErroredOnPackageTask] [varchar](1024) NULL,
	[ErrorMessage] [varchar](2048) NULL,
	[CreateUserID] [varchar](30) NOT NULL,
	[CreateDateTime] [datetime2](7) NOT NULL,
	[UpdateUserID] [varchar](30) NULL,
	[UpdateDateTime] [datetime2](7) NULL
)