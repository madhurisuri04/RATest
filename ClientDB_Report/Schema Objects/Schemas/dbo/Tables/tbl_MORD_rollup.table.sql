CREATE TABLE [dbo].[tbl_MORD_rollup]
    (
        [tbl_MORD_rollupID] INT IDENTITY(1, 1) NOT NULL ,
        [PlanIdentifier] SMALLINT NOT NULL ,
        [MORDID] INT NOT NULL ,
        [ID] INT NULL ,
        [PAYMO] NVARCHAR(8) NULL ,
        [HICN] NVARCHAR(12) NULL ,
        [AgeGroupID] INT NULL ,
        [GenderID] INT NULL ,
        [OriginallyDisabled] TINYINT NULL ,
        [RecordType] CHAR(1) NULL ,
        [BeneficiaryLastName] [VARCHAR](12) NULL ,
        [BeneficiaryFirstName] [VARCHAR](7) NULL ,
        [BeneficiaryInitial] [CHAR](1) NULL ,
        [DOB] [DATETIME] NULL ,
        [SSN] [CHAR](9) NULL ,
		[MemberIDReceived] [VARCHAR](12) NULL
    );

