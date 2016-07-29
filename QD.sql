var start_date varchar2(20)
exec :start_date := To_Date('13-Jun-2014')
var end_date varchar2(20)
exec :end_date := To_Date('23-Jul-2014')

	SELECT    sCust                     AS "IM Customer",
            IM_CUST                   AS "Customer",
			      sGroupCust                AS "Parent",
			      IM_XX_COST_CENTRE01       AS "CostCentre",
			      NI_QJ_NUMBER              AS "JobNumber",
			  	  IM_STOCK                  AS "Item",
			      IM_DESC                   AS "Description",
	          NE_QUANTITY               AS "Qty",
            NI_SELL_VALUE             AS "N Value",
	          IM_LEVEL_UNIT             AS "UOI",
	          IM_REPORTING_PRICE        AS "ReportingPrice",
            NI_SELL_VALUE * NI_QUANTITY AS "N Unit Price",
			  	  QD_COST_UNIT_PRICE        AS "QD_COST_UNIT_PRICE",
			  	  QD_SELL_UNIT_PRICE        AS "QD_SELL_UNIT_PRICE",
			  	  IL_NOTE_2                 AS "Pallet/Shelf Space",
				    IL_LOCN                   AS "Locn",
				    NE_AVAIL_ACTUAL           AS "AvailSOH",
				    substr(To_Char(NE_DATE),0,10) AS "Date",
            IM_BRAND                  AS "Brand",
            CASE
                WHEN IM_OWNED_By = 0 THEN 'COMPANY'
                WHEN IM_OWNED_By = 1 THEN 'CUSTOMER'
            END                       AS "OwnedBy",
            IM_PROFILE                AS "sProfile"
            , CASE
                WHEN NI_TRAN_TYPE = 0 THEN 'ORDER'
                WHEN NI_TRAN_TYPE = 1 THEN 'RECEIPT'
                WHEN NI_TRAN_TYPE = 2 THEN 'STOCKTAKE'
                WHEN NI_TRAN_TYPE = 3 THEN 'ISSUE'
                WHEN NI_TRAN_TYPE = 4 THEN 'TRANSFER'
                WHEN NI_TRAN_TYPE = 5 THEN 'ADJUST'
                WHEN NI_TRAN_TYPE = 6 THEN 'DEMAND'
            END AS TransactionType
            ,CASE
                WHEN NI_STATUS = 0 THEN 'EXTERNAL'
                WHEN NI_STATUS = 1 THEN 'LIVE POSITIVE'
                WHEN NI_STATUS = 2 THEN 'LIVE NEGATIVE'
                WHEN NI_STATUS = 3 THEN 'DEAD POSITIVE'
                WHEN NI_STATUS = 4 THEN 'LIVE POSITIVE'
                WHEN NI_STATUS = 5 THEN 'REVERSED'
            END AS Status
            ,CASE
                WHEN NI_STRENGTH = 0 THEN 'VOLATILE'
                WHEN NI_STRENGTH = 1 THEN 'TENTATIVE'
                WHEN NI_STRENGTH = 2 THEN 'EXPECTED'
                WHEN NI_STRENGTH = 3 THEN 'ACTUAL'
            END AS Strength,
            NI_QUANTITY,
            QD_DES_TYPE,
            QD_STATUS,
            CASE
                WHEN QD_STATUS = 0 THEN ''
                WHEN QD_STATUS = 1 THEN 'Scheduled'
                WHEN QD_STATUS = 2 THEN 'Completed'
                WHEN QD_STATUS = 3 THEN 'Charged'
                WHEN QD_STATUS = 4 THEN 'Reversed'
            END AS DespStatus,
            QD_DELIV_CODE
	FROM      PWIN175.IM
			      INNER JOIN PWIN175.NA  ON NA_STOCK = IM_STOCK
			      INNER JOIN PWIN175.IL  ON IL_UID = NA_EXT_KEY
			      INNER JOIN PWIN175.NE  ON NE_ACCOUNT  = NA_ACCOUNT
			      INNER JOIN PWIN175.NI  ON NI_ENTRY = NE_ENTRY
			      INNER JOIN Tmp_Group_Cust  ON sCust  = IM_CUST
            INNER JOIN PWIN175.QD  ON QD_JOB_NUM = NI_QJ_NUMBER AND QD_DES_SEQ = NI_QD_DES_SEQ
	WHERE     NA_EXT_TYPE = 1210067
	AND       NE_TRAN_TYPE = 1
  AND       NE_NV_EXT_TYPE = 3010144
	AND       (NE_STATUS = 1 OR NE_STATUS = 3)
	AND       NE_DATE >= :start_date AND NE_DATE <= :end_date
  AND       sGroupCust = 'METFIR'
	GROUP BY  IM_CUST,IM_XX_COST_CENTRE01,IM_STOCK,IM_DESC,IM_LEVEL_UNIT,IM_BRAND,IM_OWNED_BY, IM_PROFILE,IM_REPORTING_PRICE,
			      IL_LOCN,IL_NOTE_2,
            NE_ENTRY,NE_DATE,NE_AVAIL_ACTUAL,NE_QUANTITY,NE_ADD_DATE,NE_NV_EXT_TYPE,NA_EXT_TYPE,
            sCust,sGroupCust,
            NI_TRAN_TYPE,NI_STATUS,NI_STRENGTH,NI_QUANTITY,NI_EXT_KEY,NI_LOCN,NI_SELL_VALUE,NI_QJ_NUMBER,
            QD_SELL_UNIT_PRICE,QD_COST_UNIT_PRICE,QD_STATUS,QD_DES_TYPE,QD_DELIV_CODE
ORDER BY NE_DATE Desc