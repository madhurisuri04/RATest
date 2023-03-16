CREATE TABLE [dbo].[RollupTable](
	[RollupTableID] [int] IDENTITY(1,1) NOT NULL,
	[RollupTableName] [sysname] NOT NULL,
	[SourceTableName] [sysname] NOT NULL,
	[SourceTableSchema] [sysname] NOT NULL,
	[DateFieldForFilter] [sysname] NULL,
	[DateFieldForFilterType] [varchar](5) NULL,
	[ExecutionSequenceNumber] [smallint] NOT NULL,
	[CreateDate] [smalldatetime] NOT NULL,
	[ModifiedDate] [smalldatetime] NOT NULL,
	[FilterValuesStartWithYear] bit NULL,
	[RunGroup] [Char](2) DEFAULT '00' CHECK([RunGroup] in ('00','01','02','03','04','05'))
) 