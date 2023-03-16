-- =============================================
-- Script Template
-- =============================================

BEGIN TRANSACTION;

MERGE ref.LineofBusiness AS target
USING (

SELECT 1 AS LineOfBusinessID,'MEDICARE' AS LineofBusinessCode,'MEDICARE' AS LineofBusinessDescription, 'EU' as EncounterDiscriminator, 'AU' as SupplementalDiscriminator UNION ALL
SELECT 2 AS LineOfBusinessID,'MEDICAID' AS LineofBusinessCode ,'MEDICAID' AS LineofBusinessDescription, 'EA' as EncounterDiscriminator, 'AA' as SupplementalDiscriminator  UNION ALL
SELECT 3 AS LineOfBusinessID,'DUAL' AS LineofBusinessCode,'DUAL' AS LineofBusinessDescription, 'ED' as EncounterDiscriminator, 'AD' as SupplementalDiscriminator  UNION ALL
SELECT 4 AS LineOfBusinessID,'HHL' AS LineofBusinessCode,'HIM Historical Load' AS LineofBusinessDescription, 'EC' as EncounterDiscriminator, 'AC' as SupplementalDiscriminator UNION ALL
SELECT 5 AS LineOfBusinessID,'HIM' AS LineofBusinessCode,'Health Information Marketplace' AS LineofBusinessDescription, 'EH' as EncounterDiscriminator, 'AH' as SupplementalDiscriminator UNION ALL
SELECT 6 AS LineOfBusinessID,'RAPS' AS LineofBusinessCode,'RAPS' AS LineofBusinessDescription,'ER' AS EncounterDiscriminator,'AR' AS SupplementalDiscriminator
)
AS source
ON (target.LineOfBusinessID = source.LineOfBusinessID)
WHEN MATCHED THEN 
    UPDATE SET
		LineofBusinessCode = source.LineofBusinessCode,
		LineofBusinessDescription=source.LineofBusinessDescription,
		EncounterDiscriminator = source.EncounterDiscriminator,
		SupplementalDiscriminator = source.SupplementalDiscriminator
WHEN NOT MATCHED THEN	
    INSERT (LineOfBusinessID, LineofBusinessCode,LineofBusinessDescription, EncounterDiscriminator, SupplementalDiscriminator)
    VALUES (source.LineOfBusinessID, source.LineofBusinessCode,source.LineofBusinessDescription, source.EncounterDiscriminator, source.SupplementalDiscriminator);


COMMIT;

