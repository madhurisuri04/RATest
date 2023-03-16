CREATE PROCEDURE [dbo].[getSecurableSubject_ByName] (
	@AppCode		VARCHAR(12)
	, @Name			VARCHAR(100)
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
	WHERE LOWER([Name]) = LOWER(@Name)

END