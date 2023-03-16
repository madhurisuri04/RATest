CREATE TABLE [rev].[ProjectSubproject](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[RetroYear] [int] NOT NULL,
	[ProjectID] [int] NOT NULL,
	[ProjectDescription] [varchar](250) NOT NULL,
	[SubProjectID] [int] NOT NULL,
	[SubProjectDescription] [varchar](250) NOT NULL,
	[ClientID] [int] NOT NULL,
	[PlannedStartDate] [datetime] NOT NULL,
	[ClientLob] [varchar](75) NULL,
	[Active] [bit] NULL, 
	[LoadDatetime] [Datetime] NULL
) 