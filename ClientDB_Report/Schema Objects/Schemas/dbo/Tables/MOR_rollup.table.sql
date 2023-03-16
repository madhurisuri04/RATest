CREATE TABLE [dbo].[MOR_rollup] (
    [MOR_rollupID]       INT           IDENTITY (1, 1) NOT NULL,
    [PlanIdentifier]     SMALLINT      NOT NULL,
    [ID]                 INT           NOT NULL,
    [Paymo]              NVARCHAR (8)  NULL,
    [HICN]               NVARCHAR (12) NULL,
    [SSN]                NVARCHAR (9)  NULL,
    [ORG_DISABLD_FEMALE] SMALLINT      NULL,
    [ORG_DISABLD_MALE]   SMALLINT      NULL,
	[MemberIDReceived]	 VARCHAR(12)   NULL
);

