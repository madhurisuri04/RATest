
CREATE TABLE [dbo].[tbl_EstRecv_RAPS_Split](
	[PlanID] [int] NULL,
	[HICN] [varchar](12) NULL,
	[RAFT] [varchar](3) NULL,
	[HCC] [varchar](50) NULL,
	[HCC_Number] [int] NULL,
	[Factor] [decimal](20, 4) NULL,
	[Min_Process_By] [datetime] NULL,
	[Min_Thru] [datetime] NULL,
	[Min_ProcessBy_SeqNum] [int] NULL,
	[Min_Thru_SeqNum] [int] NULL,
	[Model_Year] [int] NULL,
	[Payment_Year] [int] NULL
) 

