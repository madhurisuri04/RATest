CREATE VIEW [dbo].[lk_TaxonomyNUCC] AS
SELECT
	[TaxonomyNUCCID],
	[Code],
	[Type],
	[Classification],
	[Specialization],
	[Definition],
	[EffectiveDate],
	[DeactivationDate],
	[LastModifiedDate],
	[Notes]
FROM [$(HRPReporting)].[dbo].[lk_TaxonomyNUCC]