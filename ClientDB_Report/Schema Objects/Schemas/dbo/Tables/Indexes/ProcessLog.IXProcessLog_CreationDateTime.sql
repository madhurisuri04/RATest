create index [IXProcessLog_CreationDateTime]
on [dbo].[ProcessLog] (CreationDateTime asc)
Include (ProcName)
on [primary]


