CREATE TABLE [dbo].[OrganizationContract]
(
	[ID]						INT IDENTITY (1, 1)		NOT NULL,
	[OrganizationID]			INT						NOT NULL,
	[LineOfBusinessID]			TINYINT					NOT NULL,
	[LOBPlanID]					VARCHAR(50)				NOT NULL,
	[LOBSubmitterIdentifier]	VARCHAR(50)				NULL,	
	[DisabledDateTime]			DATETIME2(0)	DEFAULT '12/31/2099'	NULL,
	[EffectiveStartDate]		DATETIME		DEFAULT '1/1/1900'		NULL,
	[EffectiveEndDate]			DATETIME		DEFAULT '12/31/2099'	NULL,
	[StateCodeID]				TINYINT			NULL, 
	[LoadID]					BIGINT			NULL,
	[LoadDate]					DATETIME		NULL, 
	[LastUpdatedLoadID]			BIGINT			NULL,  
	[LastUpdatedLoadDate]		DATETIME		NULL 
);

