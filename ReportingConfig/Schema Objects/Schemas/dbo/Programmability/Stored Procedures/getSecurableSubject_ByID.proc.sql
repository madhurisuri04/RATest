CREATE PROCEDURE [dbo].[getSecurableSubject_ByID] (
	@AppCode		VARCHAR(12)
	, @SubjectID	INT
) AS
BEGIN

	SELECT 
		ID
		, ParentID
		, [Name]
		, [Description]
		, UseParentDetails
		, [Type]
		, isExclusive as Exclusive
		, drawSelf
		, drawChildrenFirst 
	FROM 
		securableSubject 
	WHERE ID = @SubjectID

END