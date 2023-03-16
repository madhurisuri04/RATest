CREATE TABLE [dbo].[dbt_reconq_discrepancy] (
    [plan_id]               VARCHAR (5)   NULL,
    [discrepancy_type]      VARCHAR (50)  NULL,
    [discrepancy_timeframe] VARCHAR (1)   NULL,
    [paymstart]             SMALLDATETIME NULL,
    [period]                VARCHAR (10)  NULL,
    [discrepancy_desc]      VARCHAR (255) NULL,
    [discrepancies]         INT           NULL,
    [order_by]              INT           NULL,
    [populated]             SMALLDATETIME NULL
);

