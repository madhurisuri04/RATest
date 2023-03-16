ALTER TABLE [dve].[_CriteriaColumnMap] 
ADD CONSTRAINT [DF__CriteriaColumnMap_isDefaultLcl]  
	DEFAULT ((0)) 
	FOR [isDefaultLcl]