ALTER TABLE [dve].[_CriteriaColumnMap] 
ADD CONSTRAINT [DF__CriteriaColumnMap_isActive]  
	DEFAULT ((0)) 
	FOR [isActive]