ALTER TABLE log.HIMSubmissionFileLoad
	ADD CONSTRAINT [PK_log_HIMSubmissionFileLoad_HIMSubmissionFileLoadID] PRIMARY KEY CLUSTERED ([HIMSubmissionFileLoadID] ASC) 
	WITH (FILLFACTOR = 100, DATA_COMPRESSION = PAGE, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);