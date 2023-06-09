﻿CREATE TABLE [dbo].[tbl_BIDS_rollup] (
    [tbl_BIDS_rollupID]                                                INT           IDENTITY (1, 1) NOT NULL,
    [PlanIdentifier]                                                   SMALLINT      NOT NULL,
    [BidID]                                                            INT           NOT NULL,
    [Bid_Year]                                                         VARCHAR (4)   NULL,
    [LastModified]                                                     SMALLDATETIME NULL,
    [Low__Income_Premium]                                              SMALLMONEY    NOT NULL,
    [Low_Income_Subsidy]                                               SMALLMONEY    NOT NULL,
    [MA_BID]                                                           SMALLMONEY    NOT NULL,
    [MA_Premium]                                                       SMALLMONEY    NULL,
    [Part_D_Basic_Premium_Amount]                                      SMALLMONEY    NOT NULL,
    [Part_D_Supplemental_Premium_Amount]                               SMALLMONEY    NOT NULL,
    [PartD_BID]                                                        SMALLMONEY    NOT NULL,
    [PBP]                                                              VARCHAR (4)   NULL,
    [SCC]                                                              VARCHAR (5)   NULL,
    [SNP_Flag]                                                         VARCHAR (1)   NULL,
    [Rebate_for_Part_A_Sharing_Reduction]                              SMALLMONEY    NOT NULL,
    [Rebate_for_Part_B_Sharing_Reduction]                              SMALLMONEY    NOT NULL,
    [Rebate_for_Other_Part_A_Mandatory_Supplemental_Benefits]          SMALLMONEY    NOT NULL,
    [Rebate_for_Other_Part_B_Mandatory_Supplemental_Benefits Rebate_f] SMALLMONEY    NOT NULL,
    [Rebate_for_Part_B_Premium_Reduction_Part_A_Amount]                SMALLMONEY    NOT NULL,
    [Rebate_for_Part_B_Premium_Reduction_Part_B_Amount]                SMALLMONEY    NOT NULL,
    [Rebate_for_Part_D_Supplemental_Benefits_Part_A_Amount]            SMALLMONEY    NOT NULL,
    [Rebate_for_Part_D_Supplemental_Benefits_Part_B_Amount]            SMALLMONEY    NOT NULL,
    [Reinsurance_Subsidy_Amount]                                       SMALLMONEY    NOT NULL,
    [Rebate_for_Part_D_Basic_Benefits_Part_A_Amount]                   SMALLMONEY    NOT NULL,
    [Rebate_for_Part_D_Basic_Benefits_Part_B_Amount]                   SMALLMONEY    NOT NULL,
    PRIMARY KEY CLUSTERED ([tbl_BIDS_rollupID] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF)
);

