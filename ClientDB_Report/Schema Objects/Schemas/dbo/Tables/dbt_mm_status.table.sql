CREATE TABLE [dbo].[dbt_mm_status] (
    [plan_id]               VARCHAR (5)   NULL,
    [paymstart]             DATETIME      NULL,
    [members]               INT           NULL,
    [lis_member_count]      INT           NULL,
    [medicaid_member_count] INT           NULL,
    [hospice_member_count]  INT           NULL,
    [esrd_member_count]     INT           NULL,
    [inst_member_count]     INT           NULL,
    [disabled_member_count] INT           NULL,
    [msp_member_count]      INT           NULL,
    [order_by]              INT           NULL,
    [populated]             SMALLDATETIME NULL
);

