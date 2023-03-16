CREATE TABLE ref.LineofBusiness
(
	[LineOfBusinessID] [tinyint]  NOT NULL,
	LineofBusinessCode [varchar](10),
	LineofBusinessDescription [varchar](50),
	EncounterDiscriminator char(2),
	SupplementalDiscriminator char(2)
)
