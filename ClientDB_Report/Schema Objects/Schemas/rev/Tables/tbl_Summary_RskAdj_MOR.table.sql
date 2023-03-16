CREATE TABLE [rev].[tbl_Summary_RskAdj_MOR]
    (
     [tbl_Summary_RskAdj_MORId] BIGINT IDENTITY(1, 1) NOT NULL
   , [PlanID] INT
   , [HICN] VARCHAR(12)
   , [PaymentYear] INT NOT NULL
   , [PaymStart] DATE
   , [Model_Year] INT
   , [Factor_Category] VARCHAR(20)
   , [Factor_Description] VARCHAR(50)
   , [Factor] DECIMAL(20, 4)
   , [HCC_Number] VARCHAR(5)
   , [RAFT] CHAR(3)
   , [RAFT_ORIG] CHAR(2)
   , [HOSP] CHAR(1)
   , [OREC_CALC] VARCHAR(5)
   , [LoadDateTime] [DATETIME] NOT NULL
   , [Aged] INT NULL
   , [SubmissionModel] VARCHAR(5) NULL
   , [RecordType] CHAR(1) NULL
    )

