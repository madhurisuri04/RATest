CREATE TABLE [dbo].[ETLDerivedValue] (
    [ETLDerivedValueID]       INT            IDENTITY (1, 1) NOT NULL,
    [DerivedValueDescription] VARCHAR (1000) NULL,
    [TableName]               VARCHAR (128)  NULL,
    [ColumnName]              VARCHAR (128)  NULL,
    [GlobalLOBState]          BIT            NOT NULL,
    [OrganizationID]          INT            NOT NULL,
    [OrganizationName]        VARCHAR (255)  NULL,
    [Active]                  BIT            NOT NULL
);

