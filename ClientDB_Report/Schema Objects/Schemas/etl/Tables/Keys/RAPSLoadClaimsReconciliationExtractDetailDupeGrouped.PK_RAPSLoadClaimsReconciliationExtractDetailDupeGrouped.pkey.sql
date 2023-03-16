ALTER TABLE etl.RAPSLoadClaimsReconciliationExtractDetailDupeGrouped
       ADD CONSTRAINT [PK_RAPSLoadClaimsReconciliationExtractDetailDupeGrouped]
       PRIMARY KEY (ID)
WITH (PAD_INDEX = ON, FillFactor = 100 )