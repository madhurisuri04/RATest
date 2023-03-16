ALTER TABLE [dve].[_CriteriaColumnMap] 
ADD CONSTRAINT [DF__CriteriaColumnMap_isDefaultSrc]  
	DEFAULT ((0)) 
	FOR [isDefaultSrc]