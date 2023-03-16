CREATE PROC log.EdgeReportStatusUpdate
@EdgeReportFileLoadID BIGINT,
@FileLoadStatus VARCHAR(30),
@LoadID BIGINT
AS
BEGIN
	DECLARE @DateTime DATETIME2 = GETDATE()

	IF @FileLoadStatus = 'Success'
	BEGIN
		UPDATE [log].EdgeReportFileLoad
		SET EndDateTime = @DateTime,
		DurationInMins = DATEDIFF(minute,StartDateTime,@DateTime),
		[Status] = 'Completed',
		UpdateDateTime = @DateTime,
		UpdateUserID = SUSER_SNAME()
		where EdgeReportFileLoadID = @EdgeReportFileLoadID
	END
	ELSE IF @FileLoadStatus = 'Error'
	BEGIN
		UPDATE FL
		SET FL.EndDateTime = @DateTime,
		FL.DurationInMins = DATEDIFF(minute,FL.StartDateTime,@DateTime),
		FL.[Status] = 'Failed',
		FL.ErroredOnPackage = PE.package_name,
		FL.ErroredOnPackageTask = PE.error_source,
		FL.ErrorMessage = PE.error_description,
		FL.UpdateDateTime = @DateTime,
		FL.UpdateUserID = SUSER_SNAME()
		from [log].EdgeReportFileLoad FL
		inner join log.Package_Execution PE
		on PE.load_id = FL.LoadID
		and PE.parent_package_log_key <> PE.package_log_id 
		where EdgeReportFileLoadID = @EdgeReportFileLoadID
		and PE.[Status] = 'Failed'
		and PE.load_id = @LoadID
		and PE.parent_package_log_key = @LoadID
	END
	ELSE IF @FileLoadStatus = 'Duplicate'
	BEGIN
		UPDATE [log].EdgeReportFileLoad
		SET EndDateTime = @DateTime,
		DurationInMins = DATEDIFF(minute,StartDateTime,@DateTime),
		[Status] = 'Failed',
		ErroredOnPackage = 'Control_HIMRA_EdgeReports_Load',
		ErroredOnPackageTask = 'Duplicate File Check',
		ErrorMessage = 'Duplicate file error. File already loaded.',
		UpdateDateTime = @DateTime,
		UpdateUserID = SUSER_SNAME()
		where EdgeReportFileLoadID = @EdgeReportFileLoadID
	END
	ELSE IF @FileLoadStatus = 'IssuerNotExist'
	BEGIN
		UPDATE [log].EdgeReportFileLoad
		SET EndDateTime = @DateTime,
		DurationInMins = DATEDIFF(minute,StartDateTime,@DateTime),
		[Status] = 'Failed',
		ErroredOnPackage = 'Control_HIMRA_EdgeReports_Load',
		ErroredOnPackageTask = 'Issuer Check',
		ErrorMessage = 'Issuer Not Exist error. IssuerID does not exist in Plan',
		UpdateDateTime = @DateTime,
		UpdateUserID = SUSER_SNAME()
		where EdgeReportFileLoadID = @EdgeReportFileLoadID
	END

END
