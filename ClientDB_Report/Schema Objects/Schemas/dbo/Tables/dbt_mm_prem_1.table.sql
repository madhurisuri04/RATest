CREATE TABLE [dbo].[dbt_mm_prem] (
    [plan_id]         VARCHAR (5)     NULL,
    [paymstart]       DATETIME        NULL,
    [member_count]    INT             NULL,
    [premium]         DECIMAL (19, 4) NULL,
    [membership_type] VARCHAR (1)     NULL,
    [order_by]        INT             NULL,
    [populated]       DATETIME        NULL
);

