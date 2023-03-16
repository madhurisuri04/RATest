CREATE TABLE [dbo].[FileTypeFormatRule] (
    [ID]                       SMALLINT      IDENTITY (1, 1) NOT NULL,
    [FileTypeFormatID]         SMALLINT      NOT NULL,
    [FileTypeFormatRuleTypeID] TINYINT       NOT NULL,
    [RuleDefinition]           VARCHAR (255) NOT NULL,
    [DisabledDateTime]         DATETIME2 (7) NULL
);
