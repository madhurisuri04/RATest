CREATE TABLE [dbo].[RADVMemberRank]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[RADVStatusCodeID] int not null,
	[ProviderTypeCode] [char](2) not null,
	[RADVRank] int not null,
	[CreationDateTime] [datetime2](7) not null default getdate(),
	[LastUpdateDateTime] [datetime2](7) NULL
)
