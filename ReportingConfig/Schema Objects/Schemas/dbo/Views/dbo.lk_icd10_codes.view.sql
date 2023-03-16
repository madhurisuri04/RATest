CREATE VIEW [dbo].[lk_icd10_codes] AS 
SELECT 
	DiagnosisID,
	DiagnosisCategoryID,
	DiagnosisVolumeID,
	DiagnosisCD,
	DiagnosisCDNoDec,
	DiagShortDescription,
	DiagLongDescription,
	EffectiveDate,
	TerminationDate,
	TruncationDate,
	Flags,
	PrimaryDisallow,
	LoadID,
	LoadDate
FROM [$(HRPReporting)].[dbo].[lk_icd10_codes]