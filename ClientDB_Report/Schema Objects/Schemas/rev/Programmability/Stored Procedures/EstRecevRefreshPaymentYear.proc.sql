CREATE PROCEDURE [rev].[EstRecevRefreshPaymentYear]
( @Payment_Year int = NULL
  , @MYUFlag Varchar(1) = NULL)
AS

--Declare @Payment_Year int = 2019
--  , @MYUFlag Varchar(1) = 'N'
 /************************************************************************        
* Name			:	[EstRecevRefreshPaymentYear]     				*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	08/09/2016											*	
* Ticket        :   
* Version		:        												*
* Description	:	Refresh PY                                              *

***************************************************************************/   
/**********************************************************************************************************************************
Ticket   Date          Author           Descrition 
64005    4/24/2017     Madhuri Suri     Updating logic to work 2 PY refreshes
                                        
*************************************************************************************************************************************/

    BEGIN
        SET NOCOUNT ON

        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
             
--GET CLIENT ID 
        DECLARE @DBName VARCHAR(100)
        SELECT  @DBName = DB_NAME()
		DECLARE @PaymentYear VARCHAR(4)
	    DECLARE @MYU VARCHAR(1) 
	    DECLARE @PROCESSBY DATETIME
	   
	   


	     IF OBJECT_ID('[TEMPDB].[DBO].[#Refresh]', 'U') IS NOT NULL
            DROP TABLE dbo.#Refresh

        CREATE TABLE dbo.#Refresh
            (
              ID INT IDENTITY(1, 1) ,
              Payment_Year INT ,
              MYU VARCHAR(2) ,
              ProcessedBy DATETIME ,
              DCPFromDate DATETIME ,
              DCPThrudate DATETIME
            )



	 IF @Payment_Year IS NOT NULL AND @MYUFlag IS NOT NULL

	
	 BEGIN 


	   SET @PaymentYear = @Payment_Year
	   SET  @MYU = @MYUFlag
	  
	    INSERT  INTO dbo.#Refresh
                ( Payment_Year,
				  MYU
                )
		SELECT @PaymentYear
			  ,@MYU

        UPDATE  #Refresh
        SET     ProcessedBy = ( SELECT  CASE WHEN MIN(a.Initial_Sweep_Date) > GETDATE()
                                                THEN MIN(a.Initial_Sweep_Date)
                                                ELSE CASE
                                                WHEN MAX(a.Initial_Sweep_Date) > GETDATE()
                                                THEN MAX(a.Initial_Sweep_Date)
                                                ELSE MAX(a.Final_Sweep_Date)
                                                END
                                        END
                                FROM    [$(HRPReporting)].dbo.lk_DCP_dates a
                                WHERE   LEFT(PayMonth, 4) = @PaymentYear
                                )
        FROM    #Refresh
        WHERE   Payment_Year = @PaymentYear                      
                                          
                                          
                                          
                SET @PROCESSBY  = ( SELECT DISTINCT
                                                        processedby
                                                FROM    #Refresh
                                                WHERE   Payment_Year = @PaymentYear
                                              )

                UPDATE  #Refresh
                SET     DCPFromDate = ( SELECT DISTINCT
                                                dcp_start
                                        FROM    [$(HRPReporting)].dbo.lk_DCP_dates
                                        WHERE   Initial_Sweep_Date = @PROCESSBY
                                                OR Final_Sweep_Date = @PROCESSBY
                                      )
                FROM    #Refresh
                WHERE   Payment_Year = @PaymentYear                     
                                

                UPDATE  #Refresh
                SET     DCPThrudate = ( SELECT DISTINCT
                                                dcp_end
                                        FROM    [$(HRPReporting)].dbo.lk_DCP_dates
                                        WHERE   Initial_Sweep_Date = @PROCESSBY
                                                OR Final_Sweep_Date = @PROCESSBY
                                      )
                FROM    #Refresh
                WHERE   Payment_Year = @PaymentYear
	END 
	ELSE 
	BEGIN
	   

	SET @PaymentYear = 	   CAST(YEAR(GETDATE()) AS VARCHAR(4))
/******TBL_MMR_ROLLUP PER PLAN***/
        IF OBJECT_ID('[TEMPDB].[DBO].[#tbl_MMR_rollup]', 'U') IS NOT NULL
            DROP TABLE dbo.#tbl_MMR_rollup

        CREATE TABLE dbo.#tbl_MMR_rollup
            (
              ID INT IDENTITY(1, 1) ,
              Payment_Year INT ,
              Adjreason VARCHAR(2)
            )


        IF EXISTS ( SELECT  YEAR(PaymStart) PaymentYear ,
                            AdjReason
                    FROM    DBO.tbl_MMR_rollup
                    WHERE   RiskPymtA <> 0
                            AND AdjReason = 25
                            AND ( YEAR(PaymStart) = @PaymentYear - 1 ) )
            BEGIN 
                INSERT  INTO #tbl_MMR_rollup
                        SELECT  YEAR(PaymStart) PaymentYear ,
                                AdjReason
                        FROM    DBO.tbl_MMR_rollup
                        WHERE   RiskPymtA <> 0
                                AND YEAR(PaymStart) IN ( @PaymentYear,
                                                         @PaymentYear + 1 )
                        GROUP BY YEAR(PaymStart) ,
                                AdjReason
            END 

        ELSE
            BEGIN 

                INSERT  INTO #tbl_MMR_rollup
                        SELECT  YEAR(PaymStart) PaymentYear ,
                                AdjReason
                        FROM    DBO.tbl_MMR_rollup WITH ( NOLOCK )
                        WHERE   RiskPymtA <> 0
                                AND YEAR(PaymStart) IN ( @PaymentYear - 1,
                                                         @PaymentYear,
                                                         @PaymentYear + 1 )
                        GROUP BY YEAR(PaymStart) ,
                                AdjReason
            END 


        CREATE NONCLUSTERED INDEX TBL_MMR_ROLLUP_PLAN_IDX ON #tbl_MMR_rollup ( AdjReason, Payment_Year ) 
--SELECT * FROM #tbl_MMR_rollup
-- LOOP AND INSERT THE YEARS TO BE REFRESHED FOR ALL PLANS

        INSERT  INTO dbo.#Refresh
                ( Payment_Year
                )
                SELECT DISTINCT
                        Payment_Year
                FROM    #tbl_MMR_rollup
                ORDER BY 1 
        DECLARE @I INT
        DECLARE @ID INT = ( SELECT  COUNT(DISTINCT Payment_Year)
                            FROM    #Refresh
                          )
        SET @I = 1
        WHILE ( @I <= @ID )
            BEGIN 
    
                SELECT  @PaymentYear = Payment_Year
                FROM    #Refresh
                WHERE   ID = @I
            
                DECLARE @MYU_flag VARCHAR(1) = 'Y'          

                IF EXISTS ( SELECT  1
                            FROM    #tbl_MMR_rollup
                            WHERE   Payment_Year = @PaymentYear
                                    AND AdjReason IN ( '26', '41' ) )
                    SET @MYU_flag = 'N'
                BEGIN 
                   
                    UPDATE  #Refresh
                    SET     MYU = @MYU_flag
                    FROM    #Refresh
                    WHERE   Payment_Year = @PaymentYear                  
                    
                END
            


 /************************************************************
UPDATE VALUES FOR PROCESSEDBY AND DCP FROM AND THRU DATES :
*************************************************************/
       
                SET @MYU  = ( SELECT  myu
                                            FROM    #Refresh
                                            WHERE   Payment_Year = @PaymentYear
                                                    AND ID = @I
                                          )

                IF @MYU = 'Y'
                    BEGIN
                        UPDATE  #Refresh
                        SET     ProcessedBy = ( SELECT  CASE WHEN MIN(a.Initial_Sweep_Date) > GETDATE()
                                                             THEN MIN(a.Initial_Sweep_Date)
                                                             ELSE MAX(a.Initial_Sweep_Date)
                                                        END
                                                FROM    [$(HRPReporting)].dbo.lk_DCP_dates a
                                                WHERE   LEFT(PayMonth, 4) = @PaymentYear
                                                        AND paymonth NOT LIKE '%99'
                                              )
                        FROM    #Refresh
                        WHERE   Payment_Year = @PaymentYear
                                          
                                          
                    END
                ELSE
                    BEGIN
                        UPDATE  #Refresh
                        SET     ProcessedBy = ( SELECT  CASE WHEN MIN(a.Initial_Sweep_Date) > GETDATE()
                                                             THEN MIN(a.Initial_Sweep_Date)
                                                             ELSE CASE
                                                              WHEN MAX(a.Initial_Sweep_Date) > GETDATE()
                                                              THEN MAX(a.Initial_Sweep_Date)
                                                              ELSE MAX(a.Final_Sweep_Date)
                                                              END
                                                        END
                                                FROM    [$(HRPReporting)].dbo.lk_DCP_dates a
                                                WHERE   LEFT(PayMonth, 4) = @PaymentYear
                                              )
                        FROM    #Refresh
                        WHERE   Payment_Year = @PaymentYear                      
                                          
                                          
                                          
                    END

                SET @PROCESSBY  = ( SELECT DISTINCT
                                                        processedby
                                                FROM    #Refresh
                                                WHERE   Payment_Year = @PaymentYear
                                              )

                UPDATE  #Refresh
                SET     DCPFromDate = ( SELECT DISTINCT
                                                dcp_start
                                        FROM    [$(HRPReporting)].dbo.lk_DCP_dates
                                        WHERE   Initial_Sweep_Date = @PROCESSBY
                                                OR Final_Sweep_Date = @PROCESSBY
                                      )
                FROM    #Refresh
                WHERE   Payment_Year = @PaymentYear                     
                                

                UPDATE  #Refresh
                SET     DCPThrudate = ( SELECT DISTINCT
                                                dcp_end
                                        FROM    [$(HRPReporting)].dbo.lk_DCP_dates
                                        WHERE   Initial_Sweep_Date = @PROCESSBY
                                                OR Final_Sweep_Date = @PROCESSBY
                                      )
                FROM    #Refresh
                WHERE   Payment_Year = @PaymentYear

                SET @I = @I + 1
            END 
END
        TRUNCATE TABLE rev.EstRecevRefreshPY
 
        INSERT  INTO rev.EstRecevRefreshPY
                SELECT  [Payment_Year] ,
                        [MYU] ,
                        [ProcessedBy] ,
                        [DCPFromDate] ,
                        [DCPThrudate]
                FROM    #Refresh a

    END