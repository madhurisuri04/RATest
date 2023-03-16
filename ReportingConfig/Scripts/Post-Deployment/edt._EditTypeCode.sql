
BEGIN TRANSACTION;

TRUNCATE TABLE [edt].[_EditTypeCode];
GO

INSERT INTO [edt].[_EditTypeCode] ( [TypeCode], [Descr] ) VALUES
	( -1, 'All' ),
	( 0, 'None' ),
	( 1, 'Disabled' ),
	( 2, 'Dental' ),
	( 3, 'Institutional' ),
	( 4, 'Professional' ),
	( 5, 'DME' );
GO

COMMIT;