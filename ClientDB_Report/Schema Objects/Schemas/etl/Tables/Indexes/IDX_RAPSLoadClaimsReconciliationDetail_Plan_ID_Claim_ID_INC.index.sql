CREATE NONCLUSTERED INDEX [IDX_RAPSLoadClaimsReconciliationDetail_Plan_ID_Claim_ID_INC]
ON [etl].[RAPSLoadClaimsReconciliationDetail] ([Plan_ID], [Claim_ID])
INCLUDE ([RAPSStatusID])
WITH (PAD_INDEX = ON, FillFactor = 80 ) ON [PRIMARY]