CREATE FUNCTION ssnri.fnValidateMBI
(
	@MBI VARCHAR(20)
) 
RETURNS BIT
AS
BEGIN
/*****************************************************************************
--Object: ssnri.fnValudateMBI
--Date 04/05/2018
--Purpose: Validate the MBI String
-- Example Call SELECT ssnri.fnValidateMBI('9AT1K24PF27')
-- Modification Log:
-- 04/05/2018 MQD - initial creation TFS 70341 - used to validate any mbi 
-- string.. it must match up to the CMS pattern

/* Version History */
Author:		Rakshit Lall
Version:	1.1
Change:		Modified the function to replace SUBSTRINGS with LIKE
Date:		6/6/2018
*****************************************************************************/

-- Variable Declaration
DECLARE @return BIT = 0;

-- length must be exactly equal to 11 and match the pattern 
IF 
	LEN(@MBI) = 11
AND 
	@MBI LIKE '[1-9][aAc-hC-Hj-kJ-Km-nM-Np-rP-Rt-yT-Y][0-9aAc-hC-Hj-kJ-Km-nM-Np-rP-Rt-yT-Y][0-9][aAc-hC-Hj-kJ-Km-nM-Np-rP-Rt-yT-Y][0-9aAc-hC-Hj-kJ-Km-nM-Np-rP-Rt-yT-Y][0-9][aAc-hC-Hj-kJ-Km-nM-Np-rP-Rt-yT-Y][aAc-hC-Hj-kJ-Km-nM-Np-rP-Rt-yT-Y][0-9][0-9]'
SET @return = 1

RETURN @return
END