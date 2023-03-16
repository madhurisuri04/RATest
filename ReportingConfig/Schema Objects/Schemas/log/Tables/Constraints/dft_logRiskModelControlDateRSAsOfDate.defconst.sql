ALTER TABLE [log].[RiskModelControlDate]
    ADD CONSTRAINT [dft_logRiskModelControlDateRSAsOfDate] DEFAULT ('Today') FOR [RiskScoreAsOfDate];