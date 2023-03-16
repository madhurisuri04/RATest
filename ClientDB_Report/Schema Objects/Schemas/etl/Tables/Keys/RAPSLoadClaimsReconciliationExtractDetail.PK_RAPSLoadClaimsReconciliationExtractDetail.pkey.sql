ALTER TABLE etl.RAPSLoadClaimsReconciliationExtractDetail
       ADD CONSTRAINT [PK_RAPSLoadClaimsReconciliationExtractDetail]
       PRIMARY KEY (ID)
WITH (PAD_INDEX = ON, FillFactor = 100 )