CREATE TABLE [dbo].[dbt_mm_rs_range] (
    [plan_id]          VARCHAR (5)  NULL,
    [paymstart]        DATETIME     NULL,
    [risk_score_range] VARCHAR (50) NULL,
    [member_count]     INT          NULL,
    [order_by]         INT          NULL,
    [populated]        DATETIME     NULL
);

