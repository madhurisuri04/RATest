CREATE TABLE [dbo].[ETLTransformationLOBState] (
    [ETLTransformationLOBStateID] INT     IDENTITY (1, 1) NOT NULL,
    [ETLTransformationID]         INT     NOT NULL,
    [LineOfBusinessID]            TINYINT NOT NULL,
    [StateCodeID]                 TINYINT NOT NULL
);

