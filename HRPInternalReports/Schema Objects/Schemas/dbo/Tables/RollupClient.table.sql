CREATE TABLE [dbo].[RollupClient](
	[ClientIdentifier] [smallint] IDENTITY(1,1) NOT NULL,
	[ClientName] [varchar](100) NOT NULL,
	[UseForRollup] [bit] NOT NULL,
	[ExecutionSequenceNumber] [smallint] NOT NULL,
	[Active] [bit] NOT NULL,
	[CreateDate] [smalldatetime] NOT NULL,
	[ModifiedDate] [smalldatetime] NOT NULL
) ON [PRIMARY]