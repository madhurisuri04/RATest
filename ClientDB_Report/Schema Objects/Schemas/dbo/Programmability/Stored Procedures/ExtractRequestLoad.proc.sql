/*******************************************************************************************************************************
* Name				:	[dbo].[ExtractRequestLoad]                                                   
* Author       		:	Rakshit Lall
* Date          	:	08/24/2017
* Version			:	1.0
* Project			:	MRA Extracts
* Version History	: 
  Author			Date		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------ 
*********************************************************************************************************************************/
CREATE PROCEDURE [dbo].[ExtractRequestLoad]
	@OrganizationID INT,
	@UserID INT,
	@AppCode VARCHAR(10),
	@ExtractID BIGINT,
	@ExtractRequestID BIGINT OUTPUT,
	@XMLValue XML
		
AS

BEGIN

SET NOCOUNT ON;

SET FMTONLY OFF;

DECLARE @GETDATE DATETIME = GETDATE()
DECLARE @SYSTEMUSER SYSNAME = SYSTEM_USER

IF OBJECT_ID('TempDb..#TempXML') IS NOT NULL
DROP TABLE #TempXML

CREATE TABLE #TempXML
(
	XMLData XML	NOT NULL
)

INSERT INTO #TempXML (XMLData)
SELECT @XMLValue

DECLARE @ExtractStatusID INT = 
	(
		SELECT TOP 1 ES.ExtractStatusID
		FROM ref.ExtractStatus ES WITH(NOLOCK)
		WHERE ES.ExtractStatusCode = 'New'
	)

INSERT INTO dbo.ExtractRequest
(
	  OrganizationID
	, AppCode
	, ExtractID
	, RequestUserID
	, ExtractStatusID
	, CreatedDate
	, CreatedUser
	, UpdatedDate
	, UpdatedUser
)

SELECT
	  @OrganizationID
	, @AppCode AS AppCode
	, @ExtractID
	, @UserID AS RequestUserID
	, @ExtractStatusID AS ExtractStatusID
	, @GETDATE AS CreatedDate
	, @SYSTEMUSER AS CreatedUser
	, @GETDATE AS UpdatedDate
	, @SYSTEMUSER AS UpdatedUser	

IF @@ROWCOUNT > 0
BEGIN	
	
	SELECT 	@ExtractRequestID = SCOPE_IDENTITY()

	INSERT INTO dbo.ExtractRequestParameter
	(
		  ExtractRequestID
		, ParameterName
		, ParameterValue
		, CreatedDate
		, CreatedUser
		, UpdatedDate
		, UpdatedUser
	)
	SELECT
		  @ExtractRequestID
		, nref.value('(ParameterName)[1]', 'Varchar(MAX)') ParameterName
		, nref.value('(ParameterValue)[1]', 'Varchar(MAX)') ParameterValue
		, @GETDATE AS CreatedDate
		, @SYSTEMUSER AS CreatedUser
		, @GETDATE AS UpdatedDate
		, @SYSTEMUSER AS UpdatedUser
	FROM #TempXML t
	CROSS APPLY XMLData.nodes('/ReportParameters/Parameters') AS P(nref)
	
	RETURN (@ExtractRequestID)

END

ELSE
	SELECT 	@ExtractRequestID = 0

END
GO