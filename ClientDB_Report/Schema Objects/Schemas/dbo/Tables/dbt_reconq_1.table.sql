CREATE TABLE [dbo].[dbt_reconq] (
    [plan_id]               VARCHAR (5)   NULL,
    [discrepancy_type]      VARCHAR (50)  NULL,
    [discrepancy_timeframe] VARCHAR (1)   NULL,
    [paymstart]             SMALLDATETIME NULL,
    [period]                VARCHAR (10)  NULL,
    [discrepancies]         INT           NULL,
    [order_by]              INT           NULL,
    [populated]             SMALLDATETIME NULL
);

