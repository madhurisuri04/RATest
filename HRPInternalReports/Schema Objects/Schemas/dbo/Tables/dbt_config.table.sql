CREATE TABLE [dbo].[dbt_config] (
    [Client_ID]    INT           NULL,
    [Client_Name]  VARCHAR (100) NULL,
    [Client_DB]    VARCHAR (150) NULL,
    [Plan_ID]      VARCHAR (5)   NULL,
    [Plan_Name]    VARCHAR (100) NULL,
    [Plan_DB]      VARCHAR (150) NULL,
    [Active]       BIT           NULL,
    [PartD]        BIT           NULL,
    [Stage_Server] VARCHAR (50)  NULL
);

