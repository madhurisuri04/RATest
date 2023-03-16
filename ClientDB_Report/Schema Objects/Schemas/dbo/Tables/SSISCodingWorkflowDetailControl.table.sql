CREATE TABLE [dbo].[SSISCodingWorkflowDetailControl]
(	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ServerName]		VARCHAR(50),
	[InitialCatalog]	VARCHAR(100),
	[Email]				VARCHAR(100),
	[FilePath]			VARCHAR(200),
	[LOBID]				INT,
	[ProjectTypes]		VARCHAR(100),
	[Projects]			VARCHAR(500),
	[SubProjects]		VARCHAR(MAX),
	[ImageStatusID]		VARCHAR(50),
	[ReportType]		VARCHAR(50),
	[IsCoderMask]		VARCHAR(5),
	[IsSubscription]	CHAR(1),
	[StartDate]			DATE,
	[EndDate]			DATE,
	[Status]			INT,
	[DateInserted]		DATETIME,
	[DateStarted]		DATETIME,
	[DateEnd]			DATETIME,
	[UserID]			INT
) ON [PRIMARY]

