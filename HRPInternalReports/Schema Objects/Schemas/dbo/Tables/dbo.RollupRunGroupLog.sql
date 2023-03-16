CREATE TABLE [dbo].[RollupRunGroupLog]
(
	[RollupRunGroupID] [int] IDENTITY(1,1) NOT NULL,
	[RollupTableConfigID] [int] Not Null, 
	[RunGroup] [Char](2) Not NULL,
	[Start_Time] [datetime] NULL,
	[End_Time] [datetime] NULL,
	[Execution_Time] [varchar](30) NULL,
	[ClientIdentifier] [smallint] Null
)