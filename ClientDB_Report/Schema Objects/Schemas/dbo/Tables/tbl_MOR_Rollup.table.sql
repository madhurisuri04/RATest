CREATE TABLE [dbo].[tbl_MOR_Rollup] (
    [tbl_MOR_RollupID] [INT] IDENTITY(1, 1) NOT NULL
  , [PlanIdentifier] SMALLINT NOT NULL
  , [ID] [CHAR](10) NULL
  , [PayMonth] [VARCHAR](8) NULL
  , [HICN] [VARCHAR](12) NULL
  , [Surname] [VARCHAR](12) NULL
  , [FirstName] [VARCHAR](7) NULL
  , [Initial] [VARCHAR](1) NULL
  , [DOB] [DATETIME] NULL
  , [SSN] [CHAR](9) NULL
  , [GenderID] [INT] NULL
  , [AgeGroupID] [INT] NULL
  , [ESRD] [VARCHAR](1) NULL
  , [RecordType] [CHAR](1) NULL
  , [MemberIDReceived] [VARCHAR](12) NULL
  
)