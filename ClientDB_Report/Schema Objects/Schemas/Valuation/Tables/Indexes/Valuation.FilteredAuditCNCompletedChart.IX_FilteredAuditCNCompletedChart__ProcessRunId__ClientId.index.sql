﻿CREATE NONCLUSTERED INDEX [IX_FilteredAuditCNCompletedChart__ProcessRunId__ClientId] ON [Valuation].[FilteredAuditCNCompletedChart] 
(
[AutoProcessRunId] ASC,
[ClientId] ASC
)
INCLUDE ( [VeriskRequestId],
[ReviewName],
[SubProjectId]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF
, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON
, ALLOW_PAGE_LOCKS  = ON ) 

