CREATE TABLE dbo.tbl_EstRecv_RAPS_DiagHCC
(
RAPS_DiagHCC_rollupID	int	not null,
PlanIdentifier	smallint	null,
ProcessedBy	smalldatetime	null,
DiagnosisCode	varchar	(7)  null,	     	     
HICN	varchar	(25)	null,     	     
PatientControlNumber	varchar	(40) null,	     	     
SeqNumber	varchar	(7)	  null,   	     
ThruDate	smalldatetime null,
Deleted	varchar	(1)	null,
RAFT varchar(2) null,
Payment_year int null, 
[FileID] [varchar](18) NULL,
[Source_Id] [int] NULL,
[Provider_Id] [varchar](40) NULL,
[RAC] [varchar](1) NULL   
)