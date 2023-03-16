BEGIN TRANSACTION RAPSRollupStatus_Refresh;

TRUNCATE TABLE [eds].[EncounterRapsRollupStatus];

SET IDENTITY_INSERT [eds].[EncounterRapsRollupStatus] ON 

INSERT INTO [eds].[EncounterRapsRollupStatus] ( EncounterRapsRollupStatusID, StatusDescription ) 
VALUES 
( 1, 'VH Validated' ),
( 2, 'VH Edit Error' ),
( 3, 'CMS MAO002 Accepted' ),
( 4, 'CMS MAO002 Rejected' )

SET IDENTITY_INSERT [eds].[EncounterRapsRollupStatus] OFF 

COMMIT TRANSACTION RAPSRollupStatus_Refresh;