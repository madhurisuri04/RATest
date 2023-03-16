Create table [log].JobStatus
(
	[JobStatusID]     BIGINT IDENTITY(1,1) NOT NULL,
	[OrganizationID]  INT NOT NULL,
	[ProcessName]     VARCHAR(100) NULL, 
	[PaymentYear]     INT NULL,
	[StartDateTime]   DATETIME2 NOT NULL,
	[EndDateTime]     DATETIME2 NULL,
	[Status]          VARCHAR (20) NOT NULL, /* InProgress, Completed, Failed*/
	[LoadID]          BIGINT NOT NULL,
	[ErrorMessage]    VARCHAR(4000) NULL,
	[CreateUserID]    VARCHAR(30) NOT NULL,
	[CreateDateTime]  DATETIME2 NOT NULL,
	[UpdateUserID]    VARCHAR(30) NULL,
	[UpdateDateTime]  DATETIME2 NULL, 
	RecordsAffected	  BIGINT NULL,
	DurationInMins	  INT NULL	
)
