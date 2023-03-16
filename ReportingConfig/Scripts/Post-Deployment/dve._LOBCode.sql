
BEGIN TRANSACTION;

TRUNCATE TABLE [dve].[_LOBCode];
GO

INSERT INTO [dve].[_LOBCode] ( [LOBCode], [Descr], [EnableEdits], [EnableTransforms] ) VALUES
    ( -1, 'All', 1, 1 ),
    ( 0, 'None', 1, 1 ),
    ( 1, 'Disabled', 1, 1 ),
    ( 2, 'Medicare', 0, 0 ),
    ( 3, 'Medicaid', 0, 0 ),
    ( 4, 'Dual', 0, 0 ),
    ( 5, 'Commercial', 1, 0 ),
    ( 6, 'HIM', 0, 0 );
GO

COMMIT;