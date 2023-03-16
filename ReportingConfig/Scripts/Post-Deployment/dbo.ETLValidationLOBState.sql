
-- =============================================
-- Script Template
-- =============================================

DECLARE @ETLValidationLOBState TABLE
(
  ETLValidationLOBStateID INT NOT NULL,
  ETLValidationID INT NULL,
  LineOfBusinessID TINYINT NOT NULL,
  StateCodeID TINYINT NOT NULL
 );

INSERT INTO @ETLValidationLOBState
 (ETLValidationLOBStateID,ETLValidationID,LineofBusinessID,StateCodeID)
VALUES
 (1,1,2,5)
,(2,3,2,5)
,(3,4,2,5)
,(4,5,2,5)
,(5,6,2,5)
,(6,7,2,5)
,(7,9,2,5)
,(8,10,2,5)
,(9,13,2,5)
,(10,14,2,5)
,(11,20,2,5)
,(12,21,2,5)
,(13,22,2,5)
,(14,36,2,5)
,(15,40,2,5)
--Medicare only
,(16,10,1,45)
,(17,14,1,45)
,(18,15,1,45)
,(19,16,1,45)
,(20,24,1,45)
,(21,25,1,45)
,(22,26,1,45)
,(23,27,1,45)
,(24,28,1,45)
,(25,31,1,45)
,(26,32,1,45)
--HIM only
,(27,21,5,45)
,(28,33,5,45)
,(29,34,5,45)
,(30,35,5,45)
,(31,49,5,45)
,(32,51,5,45)
,(33,52,5,45)
,(34,53,5,45)
,(35,55,5,45)
,(36,56,5,45)
,(37,58,5,45)
,(38,59,5,45)
,(39,60,5,45)
,(40,63,5,45)
,(41,64,5,45)
,(42,65,5,45)
,(43,66,5,45)
,(44,67,5,45)
,(45,68,5,45)
,(46,69,5,45)
,(47,70,5,45)
,(48,71,5,45)
,(49,72,5,45)
,(50,73,5,45)
,(51,74,5,45)
,(52,75,5,45)
,(53,76,5,45)
,(54,77,5,45)
,(55,78,5,45)
,(56,79,5,45)
,(57,80,5,45)
,(58,81,5,45)
,(59,82,5,45)
,(60,83,5,45)
,(61,84,5,45)
,(62,85,5,45)
,(63,86,5,45)
,(64,87,5,45)
,(65,88,5,45)
,(66,89,5,45)
,(67,90,5,45)
,(68,91,5,45)
,(69,92,5,45)
,(70,93,5,45)
,(71,94,5,45)
--Added as part of #61249 ValidationID 95 for HNET Medicaid validation
,(72,95,2,5)
;

BEGIN TRANSACTION;

SET IDENTITY_INSERT ETLValidationLOBState ON;

MERGE dbo.ETLValidationLOBState AS target
USING 
  (SELECT ETLValidationLOBStateID,ETLValidationID,LineofBusinessID,StateCodeID
   FROM @ETLValidationLOBState) AS source
ON (target.ETLValidationLOBStateID = source.ETLValidationLOBStateID)
WHEN MATCHED THEN 
  UPDATE SET
      target.ETLValidationID = source.ETLValidationID,
      target.LineofBusinessID = source.LineofBusinessID,
      target.StateCodeID = source.StateCodeID
WHEN NOT MATCHED THEN  
  INSERT (ETLValidationLOBStateID,ETLValidationID,LineofBusinessID,StateCodeID)
  VALUES (source.ETLValidationLOBStateID,source.ETLValidationID,source.LineofBusinessID,source.StateCodeID);

SET IDENTITY_INSERT ETLValidationLOBState OFF;

COMMIT TRANSACTION;

