CREATE TABLE [dbo].[dbt_pde] (
    [plan_id]               VARCHAR (5)   NULL,
    [pde_date]              SMALLDATETIME NULL,
    [submissions]           INT           NULL,
    [distinct_claims_total] INT           NULL,
    [distinct_claims_acc]   INT           NULL,
    [distinct_claims_inf]   INT           NULL,
    [distinct_claims_rej]   INT           NULL,
    [distinct_claims_other] INT           NULL,
    [order_by]              INT           NULL,
    [populated]             SMALLDATETIME NULL
);

