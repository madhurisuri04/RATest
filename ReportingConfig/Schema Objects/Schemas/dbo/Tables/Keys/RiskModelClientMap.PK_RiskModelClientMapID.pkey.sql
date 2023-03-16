ALTER TABLE [dbo].[RiskModelClientMap] ADD CONSTRAINT [PK_RiskModelClientMapID]
PRIMARY KEY CLUSTERED 
(
	RiskModelClientMapID ASC
)
WITH (PAD_INDEX = ON, FillFactor = 80, Data_Compression = page)