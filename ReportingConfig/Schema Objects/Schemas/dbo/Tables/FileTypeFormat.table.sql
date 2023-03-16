CREATE TABLE [dbo].[FileTypeFormat] (
    [ID]                                  SMALLINT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [FileTypeID]                          SMALLINT      NOT NULL,
    [Name]                                VARCHAR (150) NOT NULL,
    [ImportPackage]                       VARCHAR (128) NULL,
    [ExternalTransform]                   BIT           NULL,
    [ExternalTransformUnprocessedPath]    VARCHAR (255) NULL,
    [ExternalTransformProcessedPath]      VARCHAR (255) NULL,
    [ExternalTransformPreProcessPackage]  VARCHAR (128) NULL,
    [ExternalTransformPostProcessPackage] VARCHAR (128) NULL,
    [DisabledDateTime]                    DATETIME2 (7) NULL
);