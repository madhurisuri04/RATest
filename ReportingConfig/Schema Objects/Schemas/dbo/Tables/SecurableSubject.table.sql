CREATE TABLE [dbo].[SecurableSubject] (
    [ID]                INT        IDENTITY (1, 1) NOT NULL,
    [ParentID]          INT           NULL,
    [Name]              VARCHAR (100) NOT NULL,
    [Description]       VARCHAR (250) NULL,
    [useParentDetails]  BIT           DEFAULT ((0)) NULL,
    [Type]              SMALLINT      DEFAULT ((1)) NULL,
    [isExclusive]       BIT           DEFAULT ((0)) NULL,
    [drawSelf]          BIT           DEFAULT ((1)) NULL,
    [drawChildrenFirst] BIT           DEFAULT ((0)) NULL
);

