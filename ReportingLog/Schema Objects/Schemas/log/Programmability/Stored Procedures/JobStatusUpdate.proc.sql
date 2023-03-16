/************************************************************************        
* Name			:	JobStatusUpdate										*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Balaji Dhanabalan									*
* Date          :	03/22/2016											*	
* Version		:	1.0													*
* Description	:	Update Job Status table in Reporting Log			*

* Version History : 
  Author			Date		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------  

***************************************************************************/   

CREATE PROCEDURE log.JobStatusUpdate
@Log_ID				INT,
@OrganizationID		INT,
@Process			VARCHAR(1000),
@PaymentYear		INT,
@Status				VARCHAR(1000), /* InProgress, Completed, Failed*/
@RecordsAffected	BIGINT,
@LoadID				BIGINT,
@Log_ID_Out			INT OUTPUT 
AS
BEGIN

	DECLARE @CurrentDate DATETIME2	= GETDATE()
	DECLARE @CurrentUser VARCHAR(30) = SUSER_SNAME()
	
	IF @Status = 'InProgress'
	BEGIN
		INSERT INTO log.JobStatus
		(
			OrganizationID	,
			ProcessName		,
			PaymentYear		,
			StartDateTime	,
			EndDateTime		,
			[Status]		,
			LoadID			,
			ErrorMessage	,
			CreateUserID	,
			CreateDateTime	,
			UpdateUserID	,
			UpdateDateTime	,
			RecordsAffected ,
			DurationInMins
		)
		SELECT
			@OrganizationID,
			@Process,
			@PaymentYear,
			@CurrentDate,
			NULL ,
			@Status,
			@LoadID	,
			NULL,
			@CurrentUser,
			@CurrentDate,
			@CurrentUser,
			@CurrentDate,
			NULL,
			NULL
			
		SELECT @Log_ID = SCOPE_IDENTITY()	
	END
	ELSE IF @Status = 'Completed'
	BEGIN
		UPDATE log.JobStatus
		SET EndDateTime = @CurrentDate,
		DurationInMins = DATEDIFF(minute,StartDateTime,@CurrentDate),
		[Status] = @Status,
		UpdateDateTime = @CurrentDate,
		UpdateUserID = @CurrentUser,
		RecordsAffected = @RecordsAffected
		where JobStatusID = @Log_ID
	END
	ELSE IF @Status = 'Failed'
	BEGIN
		IF (select COUNT(1) 
				from log.Package_Execution PEC
				where PEC.load_id = @LoadID
				and PEC.parent_package_log_key <> PEC.package_log_id 
			) > 0
			UPDATE FL
			SET FL.EndDateTime = @CurrentDate,
			FL.DurationInMins = DATEDIFF(minute,FL.StartDateTime,@CurrentDate),
			FL.[Status] = @Status,
			FL.ErrorMessage = 'Package Name: ' + PE.package_name + ', Error Source: ' + PE.error_source + ', Error Description: ' + PE.error_description,
			FL.UpdateDateTime = @CurrentDate,
			FL.UpdateUserID = @CurrentUser,
			FL.RecordsAffected = @RecordsAffected
			from log.JobStatus FL
			inner join log.Package_Execution PE
			on PE.load_id = FL.LoadID
			and PE.parent_package_log_key <> PE.package_log_id 
			where JobStatusID = @Log_ID
			and PE.[Status] = @Status
			and PE.load_id = @LoadID
			and PE.parent_package_log_key = @LoadID
		ELSE
			UPDATE FL
			SET FL.EndDateTime = @CurrentDate,
			FL.DurationInMins = DATEDIFF(minute,FL.StartDateTime,@CurrentDate),
			FL.[Status] = @Status,
			FL.ErrorMessage = 'Package Name: ' + PE.package_name + ', Error Source: ' + PE.error_source + ', Error Description: ' + PE.error_description,
			FL.UpdateDateTime = @CurrentDate,
			FL.UpdateUserID = @CurrentUser,
			FL.RecordsAffected = @RecordsAffected
			from log.JobStatus FL
			inner join log.Package_Execution PE
			on PE.load_id = FL.LoadID
			and PE.parent_package_log_key = PE.package_log_id 
			where JobStatusID = @Log_ID
			and PE.[Status] = @Status
			and PE.load_id = @LoadID
			and PE.parent_package_log_key = @LoadID
	END

	SELECT @Log_ID_Out = @Log_ID
END