
CREATE PROCEDURE dbo.spr_dbt_master

AS

BEGIN
	EXEC spr_dbt_mm_rs					-- 1
	EXEC spr_dbt_mm_prem				-- 2
	EXEC spr_dbt_mm_rs_range			-- 3
	EXEC spr_dbt_mm_ra_factor			-- 4
	EXEC spr_dbt_mm_retro				-- 5
	EXEC spr_dbt_mm_status				-- 6
	EXEC spr_dbt_reconq					-- 7
	EXEC spr_dbt_reconq_discrepancy		-- 8
	EXEC spr_dbt_reconq_aging			-- 9		
	EXEC spr_dbt_pde					-- 10
	EXEC spr_dbt_pdeq					-- 11
	EXEC spr_dbt_raps					-- 12
	EXEC spr_dbt_top_10_HCC				-- 13a
	EXEC spr_dbt_top_10_HCC_plan		-- 13b
	EXEC spr_dbt_hcc_prov_type			-- 14
	EXEC spr_dbt_cn_qa					-- 15a
	EXEC spr_dbt_cn_tracking			-- 15b
	EXEC spr_dbt_raps_submissions		-- 16
	EXEC spr_dbt_hcc_prov_type			-- 17
	EXEC spr_dbt_file_upload			-- 18
	-- Add additional procs. Eventaully make table drivem before full IT automation.
	
END