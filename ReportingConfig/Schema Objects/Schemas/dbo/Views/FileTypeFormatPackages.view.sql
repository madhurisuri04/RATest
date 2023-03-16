CREATE VIEW [dbo].[FileTypeFormatPackages] AS

SELECT  
   P.FileTypeFormatID,
   FT.Name As FileTypeName,
   FTF.Name As FileFormatName,
   P.Idx,					
   P.PackageName			
FROM  
    dbo.FileTypeFormat FTF
    LEFT OUTER JOIN dbo.FileType FT ON (FTF.FileTypeID = FT.ID)
CROSS APPLY 
    dbo.SplitFileTypeFormatPackages (FTF.ID)  AS P 
