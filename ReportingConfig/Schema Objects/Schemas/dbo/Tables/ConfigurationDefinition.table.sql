CREATE TABLE [dbo].[ConfigurationDefinition] (
    [ID]                       INT           NOT NULL,
    [ConfigurationType]        VARCHAR (50)  NOT NULL,
    [ConfigurationDescription] VARCHAR (500) NULL,
    [DefaultValue]             VARCHAR (256) NULL,
    [CreateUserID]             INT           NOT NULL,
    [CreateDateTime]           DATETIME2 (7) NOT NULL,
    [LastUpdateUserID]         INT           NOT NULL,
    [LastUpdateDateTime]       DATETIME2 (7) NOT NULL
);