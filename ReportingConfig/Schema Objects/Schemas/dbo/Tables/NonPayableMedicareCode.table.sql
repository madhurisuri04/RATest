CREATE TABLE [dbo].[NonPayableMedicareCode](
	[ProcCodeID] [int] IDENTITY(1,1) NOT NULL,
	[ProcCode] [varchar](255) NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[ReasonForDeletion] [varchar](1024) NULL
)