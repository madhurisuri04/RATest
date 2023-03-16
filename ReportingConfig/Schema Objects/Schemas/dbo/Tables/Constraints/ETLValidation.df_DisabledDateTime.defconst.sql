ALTER TABLE [dbo].[ETLValidation]
   ADD CONSTRAINT [df_DisabledDateTime] 
   DEFAULT '9999-12-31 00:00:00'
   FOR DisabledDateTime


