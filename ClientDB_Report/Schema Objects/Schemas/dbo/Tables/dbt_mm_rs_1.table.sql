CREATE TABLE [dbo].[dbt_mm_rs] (
    [plan_id]         VARCHAR (5)     NULL,
    [payment_year]    VARCHAR (4)     NULL,
    [prior_year]      VARCHAR (4)     NULL,
    [member_count]    INT             NULL,
    [avg_risk_score]  DECIMAL (19, 4) NULL,
    [membership_type] VARCHAR (1)     NULL,
    [populated]       DATETIME        NULL
);

