ALTER TABLE [dve].[_CriteriaColumnMap] 
ADD CONSTRAINT [DF__CriteriaColumnMap_SourceEntity]  
	DEFAULT ((0)) 
	FOR [SourceEntity]