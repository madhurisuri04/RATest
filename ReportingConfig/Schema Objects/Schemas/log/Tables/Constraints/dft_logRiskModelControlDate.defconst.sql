ALTER TABLE [log].[RiskModelControlDate]
    ADD CONSTRAINT [dft_logRiskModelControlDate] DEFAULT (60) FOR [DaysActiveAfterFreezeDate];