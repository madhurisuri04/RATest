CREATE NONCLUSTERED INDEX [IX_FilteredAuditCNCompletedChart__AutoProcessRunId] ON [Valuation].[FilteredAuditCNCompletedChart] 
(
[AutoProcessRunId] ASC,
[SubProjectId] ASC,
[ClientId] ASC
)
INCLUDE ( [ReviewName],
[VeriskRequestId]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF
, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON
 ) 
