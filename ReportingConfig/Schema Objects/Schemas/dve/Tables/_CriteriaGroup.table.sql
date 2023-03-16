﻿CREATE TABLE [dve].[_CriteriaGroup] (
	GroupID			TINYINT			IDENTITY(1,1) NOT NULL,
	GroupName		VARCHAR(50)		NOT NULL,
	GroupDescr		VARCHAR(500)	NULL,
	CONSTRAINT [PK__CriteriaGroup] PRIMARY KEY CLUSTERED (
		[GroupID] ASC
	) WITH (
		PAD_INDEX = OFF, 
		STATISTICS_NORECOMPUTE = OFF, 
		IGNORE_DUP_KEY = OFF, 
		ALLOW_ROW_LOCKS = ON, 
		ALLOW_PAGE_LOCKS  = ON
	) ON [PRIMARY]
) ON [PRIMARY]