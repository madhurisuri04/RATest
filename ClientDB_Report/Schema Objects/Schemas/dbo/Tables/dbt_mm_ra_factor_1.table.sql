CREATE TABLE [dbo].[dbt_mm_ra_factor] (
    [plan_id]        VARCHAR (5)   NULL,
    [paymstart]      DATETIME      NULL,
    [ra_factor_type] VARCHAR (4)   NULL,
    [ra_factor_desc] VARCHAR (510) NULL,
    [member_count]   INT           NULL,
    [order_by]       INT           NULL,
    [populated]      SMALLDATETIME NULL
);

