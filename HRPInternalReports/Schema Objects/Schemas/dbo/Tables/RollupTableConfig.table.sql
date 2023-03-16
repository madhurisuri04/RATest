CREATE TABLE [dbo].[RollupTableConfig](
	[RollupTableConfigID] [int] IDENTITY(1,1) NOT NULL,
	[ClientIdentifier] [smallint] NOT NULL,
	[RollupTableID] [int] NOT NULL,
	[RollingYearsFilter] [int] NULL,
	[DynamicRollup] [bit] NOT NULL,
	[Active] [bit] NOT NULL,
	[CreateDate] [smalldatetime] NOT NULL,
	[ModifiedDate] [smalldatetime] NOT NULL,
	[IncludeNullDates] bit NULL,
	[IncludeInvalidDates] bit NULL,
	[TruncateTable] bit null
)