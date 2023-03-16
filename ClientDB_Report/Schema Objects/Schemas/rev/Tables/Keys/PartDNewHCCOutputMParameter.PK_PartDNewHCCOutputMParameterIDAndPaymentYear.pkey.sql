ALTER TABLE rev.PartDNewHCCOutputMParameter
ADD CONSTRAINT [PKrevPartDNewHCCOutputMParameterID] PRIMARY KEY CLUSTERED ([PartDNewHCCOutputMParameterID] ASC, [PaymentYear] ASC)
WITH (FILLFACTOR = 100 , ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF)
ON [pscheme_SummPY](PaymentYear)