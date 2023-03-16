﻿Create Table dbo.Raps_Accepted_rollup
( 
	Raps_Accepted_rollupID	int Identity NOT NULL,
	PlanIdentifier			smallint Not Null,
	RAPSID					int not null,
	ProcessedBy				smalldatetime Not Null,
	FileID					varchar(18) Null,
	RecordID				varchar(3) Null,
	SeqNumber				varchar(7) Null,
	PatientControlNumber	varchar(40) Null,
	HICN					varchar(25) Null,
	HICNError				varchar(3) Null,
	CorrectedHICN			varchar(25) Null,
	ProviderType			varchar(2) NULL,
	FromDate				smalldatetime Null,
	ThruDate				smalldatetime Null,
	Deleted					varchar(1) Null,
	DiagnosisCode			varchar(7) Null,
	DCFiller				varchar(2) Null,
	DiagnosisError1			varchar(3) Null,
	DiagnosisError2			varchar(3) Null,
	Filler					varchar(75) NULL,
	Source_ID				int null,
	Provider_ID				varchar(40) null,
	RAC						char(1)  null,
	RAC_Error				varchar(3) null,
	Image_ID				int null,
	ImportedDate			smalldatetime null
)