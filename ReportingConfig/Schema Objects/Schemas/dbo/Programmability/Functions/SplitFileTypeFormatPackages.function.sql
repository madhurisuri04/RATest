
CREATE FUNCTION [dbo].[SplitFileTypeFormatPackages]
(
	@FileTypeFormatID	smallint
)
RETURNS 
@tbl_values TABLE 
(
	FileTypeFormatID	smallint,
	idx					int,
	PackageName			varchar(max)
)
AS
BEGIN
	INSERT	@tbl_values

		SELECT	
			@FileTypeFormatID,
			idx,
			rtrim(ltrim(value)) AS PackageName
		FROM dbo.Split
		   (
		   (SELECT ImportPackage FROM FileTypeFormat WHERE [ID] = @FileTypeFormatID),
		   ','
		   )
		WHERE RTRIM(LTRIM(value)) <> ''
		
	RETURN
END