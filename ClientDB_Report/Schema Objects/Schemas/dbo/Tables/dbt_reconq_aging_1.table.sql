CREATE TABLE [dbo].[dbt_reconq_aging] (
    [plan_id]                    VARCHAR (5)   NULL,
    [discrepancy_status]         VARCHAR (50)  NULL,
    [action_or_resolved_status]  VARCHAR (50)  NULL,
    [discrepancy_type]           VARCHAR (50)  NULL,
    [<=30 days]                  INT           NULL,
    [31-60 days]                 INT           NULL,
    [61-90 days]                 INT           NULL,
    [91-120]                     INT           NULL,
    [>120]                       INT           NULL,
    [total_mbrs]                 INT           NULL,
    [total_mms]                  INT           NULL,
    [negative_expected_variance] MONEY         NULL,
    [positive_expected_variance] MONEY         NULL,
    [total_expected_variance]    MONEY         NULL,
    [payment_start]              SMALLDATETIME NULL,
    [payment_end]                SMALLDATETIME NULL,
    [order_by]                   INT           NULL,
    [populated]                  SMALLDATETIME NULL
);

