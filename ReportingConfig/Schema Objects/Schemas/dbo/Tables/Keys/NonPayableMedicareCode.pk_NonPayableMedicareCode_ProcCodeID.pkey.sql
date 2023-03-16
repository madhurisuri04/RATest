
ALTER TABLE [dbo].[NonPayableMedicareCode]
  ADD CONSTRAINT pk_NonPayableMedicareCode_ProcCodeID PRIMARY KEY CLUSTERED(ProcCodeID) WITH (data_compression = page, FILLFACTOR = 95);