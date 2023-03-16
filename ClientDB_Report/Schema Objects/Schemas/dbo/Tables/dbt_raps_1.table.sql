CREATE TABLE [dbo].[dbt_raps] (
    [plan_id]        VARCHAR (5)   NULL,
    [processedby]    DATE          NULL,
    [error_1]        VARCHAR (15)  NULL,
    [delete_ind]     VARCHAR (2)   NULL,
    [descr]          VARCHAR (250) NULL,
    [diag_count]     INT           NULL,
    [total_accepted] INT           NULL,
    [total_rejected] INT           NULL,
    [percentage]     FLOAT         NULL,
    [order_by]       INT           NULL,
    [populated]      SMALLDATETIME NULL
);

