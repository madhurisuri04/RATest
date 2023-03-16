ALTER TABLE [log].JobStatus
ADD CONSTRAINT [PK_JobStatus_JobStatusID] PRIMARY KEY CLUSTERED 
(JobStatusID ASC)  WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
