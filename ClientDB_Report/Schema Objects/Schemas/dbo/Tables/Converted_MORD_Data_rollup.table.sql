CREATE TABLE [dbo].[Converted_MORD_Data_rollup]
    (
        [Converted_MORD_Data_rollupID] INT IDENTITY(1, 1) NOT NULL ,
        [PlanIdentifier] SMALLINT NOT NULL ,
        [Payment_Month] VARCHAR(8) NULL ,
        [HICN] VARCHAR(12) NULL ,
        [Description] VARCHAR(255) NULL ,
        [Name] VARCHAR(50) NULL ,
        [RecordType] CHAR(1) NULL ,
        [Surname] VARCHAR(12) NULL ,
        [FirstName] VARCHAR(7) NULL ,
        [Comm] FLOAT NULL,
		[MemberIDReceived] VARCHAR(12)	NULL
    );
