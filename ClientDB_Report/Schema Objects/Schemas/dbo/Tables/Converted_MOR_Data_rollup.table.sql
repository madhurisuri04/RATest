CREATE TABLE [dbo].[Converted_MOR_Data_rollup] (
    [Converted_MOR_Data_rollupID] INT           IDENTITY (1, 1) NOT NULL,
    [PlanIdentifier]              SMALLINT      NOT NULL,
    [PayMonth]                    VARCHAR (8)   NULL,
    [HICN]                        VARCHAR (12)  NULL,
    [Surname]                     VARCHAR (12)  NULL,
    [FirstName]                   VARCHAR (7)   NULL,
    [Name]                        VARCHAR (50)  NULL,
    [Description]                 VARCHAR (255) NULL,
    [Comm]                        FLOAT         NULL,
	[RecordType]				  CHAR(1)		NULL,
	[MemberIDReceived]            VARCHAR(12)   NULL    
);

