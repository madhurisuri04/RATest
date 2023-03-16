CREATE TABLE [dbo].[MOR2012_rollup]
(
	[MOR2012_rollupID]			INT IDENTITY(1,1)	NOT NULL,
	[PlanIdentifier]				SMALLINT			NOT NULL,
    [ID]							INT					NOT NULL,
	[Paymo]							VARCHAR(8)			NULL,
	[HICN]							VARCHAR(12)			NULL,
	[SSN]							VARCHAR(9)			NULL,
	[ORG_DISABLD_FEMALE]			TINYINT				NULL,
	[ORG_DISABLD_MALE]				TINYINT				NULL,
	[MemberIDReceived]	            VARCHAR(12)         NULL	
) 
