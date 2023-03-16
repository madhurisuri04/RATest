/* TFS 42301 - One time execution for clear off the RIDE and RISR loads  */
DECLARE @ServerName VARCHAR(25)
SET @ServerName = @@ServerName

IF @@ServerName = 'HRPDB001' 
BEGIN
	
	UPDATE log.EdgeReportFileLoad
	SET Status = 'RELOAD',
	UpdateUserID = suser_sname(),
	UpdateDateTime = GETDATE()
	where ReportType = 'RISR' 
	AND Status = 'Completed'
	

	UPDATE log.EdgeReportFileLoad
	SET Status = 'RELOAD',
	UpdateUserID = suser_sname(),
	UpdateDateTime = GETDATE()
	where ReportType = 'RIDE' 
	AND Status = 'Completed'
	
END



