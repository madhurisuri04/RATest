ALTER TABLE [dbo].[ExtractDelivery]
	ADD CONSTRAINT [PK_ExtractDelivery] PRIMARY KEY CLUSTERED ([ExtractDeliveryID] ASC) 
	WITH (FILLFACTOR = 100 , ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);