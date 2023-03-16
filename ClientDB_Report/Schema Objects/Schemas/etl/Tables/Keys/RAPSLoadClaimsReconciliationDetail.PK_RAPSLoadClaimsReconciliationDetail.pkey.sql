ALTER TABLE etl.RAPSLoadClaimsReconciliationDetail
       ADD CONSTRAINT [PK_RAPSLoadClaimsReconciliationDetail]
       PRIMARY KEY (ID)
WITH (PAD_INDEX = ON, FillFactor = 100 )