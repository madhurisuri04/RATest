CREATE TABLE [dbo].[dbt_mm_retro] (
    [plan_id]                VARCHAR (5)   NULL,
    [paymstart]              DATETIME      NULL,
    [adjustment_reason]      VARCHAR (3)   NULL,
    [adjustment_reason_desc] VARCHAR (250) NULL,
    [member_count]           INT           NULL,
    [order_by]               INT           NULL,
    [populated]              SMALLDATETIME NULL
);

