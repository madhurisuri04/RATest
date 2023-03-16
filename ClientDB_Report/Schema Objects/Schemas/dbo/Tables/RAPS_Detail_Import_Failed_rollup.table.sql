CREATE TABLE [dbo].[RAPS_Detail_Import_Failed_rollup] (
	[RAPS_Detail_Import_Failed_rollupID] BIGINT identity (1, 1) NOT NULL
	, PlanIdentifier			SMALLINT			NULL
	, ID						BIGINT				NOT NULL 
    , [PLAN_ID]					VARCHAR (5)			NULL 
    , [CLAIM_CONTROL_NUMBER]	VARCHAR (100)		NULL 
    , [HICN]					VARCHAR (50)		NULL 
    , [DATE_OF_SERVICE_START]	VARCHAR (15)		NULL 
    , [DATE_OF_SERVICE_END]		VARCHAR (15)		NULL 
    , [PROVIDER_TYPE]			VARCHAR (5)			NULL 
    , [DIAG1]					VARCHAR (20)		NULL 
    , [DIAG2]					VARCHAR (20)		NULL 
    , [DIAG3]					VARCHAR (20)		NULL 
    , [DIAG4]					VARCHAR (20)		NULL 
    , [DIAG5]					VARCHAR (20)		NULL 
    , [DIAG6]					VARCHAR (20)		NULL 
    , [DIAG7]					VARCHAR (20)		NULL 
    , [DIAG8]					VARCHAR (20)		NULL 
    , [DIAG9]					VARCHAR (20)		NULL 
    , [DIAG10]					VARCHAR (20)		NULL 
    , [DELDIAG1]				VARCHAR (1)			NULL 
    , [DELDIAG2]				VARCHAR (1)			NULL 
    , [DELDIAG3]				VARCHAR (1)			NULL 
    , [DELDIAG4]				VARCHAR (1)			NULL 
    , [DELDIAG5]				VARCHAR (1)			NULL 
    , [DELDIAG6]				VARCHAR (1)			NULL 
    , [DELDIAG7]				VARCHAR (1)			NULL 
    , [DELDIAG8]				VARCHAR (1)			NULL 
    , [DELDIAG9]				VARCHAR (1)			NULL 
    , [DELDIAG10]				VARCHAR (1)			NULL 
	, [Source_ID]				VARCHAR(10)			NULL	
	, [Provider_ID]				VARCHAR(40)			NULL 
	, ICD1						CHAR(1)				NULL 
	, RAC1						CHAR(1)				NULL 
	, ICD2						CHAR(1)				NULL 
	, RAC2						CHAR(1)				NULL 
	, ICD3						CHAR(1)				NULL 
	, RAC3						CHAR(1)				NULL 
	, ICD4						CHAR(1)				NULL 
	, RAC4						CHAR(1)				NULL 
	, ICD5						CHAR(1)				NULL 
	, RAC5						CHAR(1)				NULL 
	, ICD6						CHAR(1)				NULL 
	, RAC6						CHAR(1)				NULL 
	, ICD7						CHAR(1)				NULL 
	, RAC7						CHAR(1)				NULL 
	, ICD8						CHAR(1)				NULL 
	, RAC8						CHAR(1)				NULL 
	, ICD9						CHAR(1)				NULL 
	, RAC9						CHAR(1)				NULL 
	, ICD10						CHAR(1)				NULL 
	, RAC10						CHAR(1)				NULL 
	, OVERPAYMENT_INDICATOR		CHAR(1)				NULL 
	, REMEDY_TICKET_NUMBER		VARCHAR(20)			NULL 
	, Upload_ID					INT					NULL 
    , IsProcessed				BIT					NOT NULL 
	, RAPSStatusID				TINYINT				NULL 
); 
