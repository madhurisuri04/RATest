ALTER TABLE [dve].[_CriteriaColumnMap] 
ADD CONSTRAINT [DF__CriteriaColumnMap_LocalEntity]  
	DEFAULT ((0)) 
	FOR [LocalEntity]