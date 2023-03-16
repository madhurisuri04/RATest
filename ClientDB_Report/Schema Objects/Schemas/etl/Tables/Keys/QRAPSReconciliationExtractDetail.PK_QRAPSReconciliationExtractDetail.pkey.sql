ALTER TABLE etl.QRAPSReconciliationExtractDetail
       ADD CONSTRAINT [PK_QRAPSReconciliationExtractDetail]
       PRIMARY KEY (ID)
WITH (PAD_INDEX = ON, FillFactor = 100)