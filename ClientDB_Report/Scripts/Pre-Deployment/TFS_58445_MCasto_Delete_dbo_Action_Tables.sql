-- =============================================
-- Author:	Mitch Casto
-- Date:	2016-10-18
--Ticket:	58445
-- =============================================



IF EXISTS (SELECT *
             FROM [sys].[objects]
            WHERE [object_id] = OBJECT_ID(N'[dbo].[AutoProcessAction]')
              AND [type] IN (N'U'))
    BEGIN
        DROP TABLE [dbo].[AutoProcessAction]
    END
GO


IF EXISTS (SELECT *
             FROM [sys].[objects]
            WHERE [object_id] = OBJECT_ID(N'[dbo].[AutoProcessActionCatalog]')
              AND [type] IN (N'U'))
    BEGIN

        DROP TABLE [dbo].[AutoProcessActionCatalog]
    END
GO


IF EXISTS (SELECT *
             FROM [sys].[objects]
            WHERE [object_id] = OBJECT_ID(N'[dbo].[AutoProcessActionCatalogParameter]')
              AND [type] IN (N'U'))
    BEGIN
        DROP TABLE [dbo].[AutoProcessActionCatalogParameter]
    END
GO


IF EXISTS (SELECT *
             FROM [sys].[objects]
            WHERE [object_id] = OBJECT_ID(N'[dbo].[AutoProcessWorkList]')
              AND [type] IN (N'U'))
    BEGIN
        DROP TABLE [dbo].[AutoProcessWorkList]
    END
GO