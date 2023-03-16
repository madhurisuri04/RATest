CREATE NONCLUSTERED INDEX [tbl_Plan_Claims_Validation_rollup_PlanIdentifier_Claim_ID]
ON [dbo].[tbl_Plan_Claims_Validation_rollup] ([PlanIdentifier],[Claim_ID])
WITH (PAD_INDEX = ON, FillFactor = 80 ) ON [PRIMARY]