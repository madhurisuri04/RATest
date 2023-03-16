--TFS-75663
--Created by: Krishna Acharya

-- Rebranding Verscend to Cotiviti
WHILE (1 = 1)
BEGIN
	UPDATE TOP (1000000) CWD
	SET CWD.suspectsource = 'Cotiviti'
	FROM [dbo].CWFDetails CWD
	WHERE CWD.suspectsource = 'Verscend';

	IF @@ROWCOUNT = 0
		BREAK
	ELSE
		CONTINUE
END
GO


 