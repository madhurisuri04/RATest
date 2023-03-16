CREATE PROCEDURE [dbo].[getSecurableSubjects_All] 

AS

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


END