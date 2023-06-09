﻿CREATE TABLE [dbo].[LogAutoProcessActionCatalog](
	[LogAutoProcessActionCatalogId] [int] IDENTITY(1,1) NOT NULL,
	[AutoProcessActionCatalogId] [int] NULL,
	[AutoProcessStepName] [varchar](128) NULL,
	[AutoProcessStepName_old] [varchar](128) NULL,
	[Description] [varchar](512) NULL,
	[Description_old] [varchar](512) NULL,
	[CommandDb] [varchar](130) NULL,
	[CommandDb_old] [varchar](130) NULL,
	[CommandSchema] [varchar](130) NULL,
	[CommandSchema_old] [varchar](130) NULL,
	[CommandSTP] [varchar](130) NULL,
	[CommandSTP_old] [varchar](130) NULL,
	[ByPlan] [bit] NULL,
	[ByPlan_old] [bit] NULL,
	[DependAutoProcessActionCatalogId] [int] NULL,
	[DependAutoProcessActionCatalogId_old] [int] NULL,
	[PopulateParameter] [bit] NULL,
	[PopulateParameter_old] [bit] NULL,
	[ActiveBDate] [date] NULL,
	[ActiveBDate_old] [date] NULL,
	[ActiveEDate] [date] NULL,
	[ActiveEDate_old] [date] NULL,
	[Added] [datetime] NULL,
	[Added_old] [datetime] NULL,
	[AddedBy] [varchar](257) NULL,
	[AddedBy_old] [varchar](257) NULL,
	[Edited] [datetime] NULL,
	[EditedBy] [varchar](257) NULL,
    [Action] [char](1) NULL


 )