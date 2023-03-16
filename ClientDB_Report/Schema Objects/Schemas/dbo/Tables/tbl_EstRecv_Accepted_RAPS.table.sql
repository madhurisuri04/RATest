
CREATE TABLE [dbo].[tbl_EstRecv_Accepted_RAPS](
	[PlanID] [int] NULL,
	[HICN] [varchar](12) NULL,
	[RAFT] [varchar](3) NULL,
	[HCC] [varchar](50) NULL,
	[HCC_Number] [int] NULL,
	[Min_Process_By] [datetime] NULL,
	[Min_Thru] [datetime] NULL,
	[Min_ProcessBy_SeqNum] [int] NULL,
	[Min_Thru_SeqNum] [int] NULL,
	[Deleted] char(1) NULL
) 


