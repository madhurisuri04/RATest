ALTER TABLE etl.RAPSLoadClaimsReconciliationExtractDetailDupeNotGrouped
       ADD CONSTRAINT [PK_RAPSLoadClaimsReconciliationExtractDetailDupeNotGrouped]
       PRIMARY KEY (ID)
WITH (PAD_INDEX = ON, FillFactor = 100 )