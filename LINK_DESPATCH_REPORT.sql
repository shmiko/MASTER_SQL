SELECT    substr(To_Char(ST.ST_DESP_DATE),0,10) AS "DespatchDate"
                ,substr(To_Char(SH.SH_ADD_DATE),0,10) AS "OrderDate"
                ,Tmp_Group_Cust.sGroupCust   AS "Parent"
                ,SH.SH_CUST AS "Cust"
               ,RM.RM_NAME AS "CustName"
               ,SD.SD_XX_PICKLIST_NUM     AS "PickSlip"
               ,ST.ST_PSLIP               AS "DespatchNote"
               ,SH.SH_ORDER            AS "Order#"
               ,SH.SH_SPARE_STR_5         AS "OrderwareNum"
               ,SH.SH_CUST_REF                AS "Cust Ref"
               ,SD.SD_STOCK               AS "Stock"
               ,SD.SD_DESC                AS "Description"
               ,SD.SD_QTY_ORDER           AS "Qty Ordered"
               ,SD.SD_QTY_UNIT            AS "UOI"
               ,SL.SL_PSLIP_QTY           AS "Qty Despatched"
               ,ST.ST_WEIGHT AS "Weight"
               ,ST.ST_PACKAGES AS "Packages"
               ,IM.IM_REPORTING_PRICE          AS "Price(IM)"
               ,IM.IM_SCALE_LCL                       AS "LCL Scale"
               ,SD.SD_SELL_PRICE         AS "SD_SELL_PRICE"
               ,'FIFO'         AS "FIFO Unit Price"
               ,NI.NI_SELL_VALUE AS "BatchUnitSellPrice"
               ,SD.SD_EXCL AS "Ext GST Sell"
               ,SD.SD_TAX AS "GST"
               ,SD.SD_INCL AS "Incl GST"
               ,SH.SH_ADDRESS             AS "Address"
               ,SH.SH_SUBURB              AS "Address2"
               ,SH.SH_CITY                AS "Suburb"
               ,SH.SH_STATE               AS "State"
               ,SH.SH_POST_CODE           AS "Postcode"
               ,SH.SH_NOTE_2              AS "AttentionTo"
               ,SH.SH_NOTE_1              AS "DeliverTo"
               ,SH.SH_SPARE_STR_4             AS "CostCenter"
               ,NULL            AS "RD_SPARE_STR_1"
               ,SH.SH_SPARE_STR_6         AS "Ordered By"
               ,IM.IM_OWNED_BY AS "OwnedBy"
               ,IM.IM_BRAND AS "Finish"
               ,SD.SD_LINE AS "OWLineNum"
               ,IM.IM_FINISH AS "Finish"
               ,ST.ST_SPARE_INT_1 AS "SentFrom"
               ,NULL
               ,NULL
               ,NULL
               ,NULL
               ,NULL,
               NULL,NULL,NULL,NULL
      FROM  PWIN175.SD
            RIGHT JOIN PWIN175.SH  ON SH.SH_ORDER  = SD.SD_ORDER
            LEFT JOIN PWIN175.ST  ON ST.ST_PICK  = SD.SD_LAST_PICK_NUM
            LEFT JOIN PWIN175.SL   ON SL.SL_PICK   = ST.ST_PICK
            INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
            --INNER JOIN PWIN175.RD  ON RD.RD_CODE  = SH.SH_DEL_CODE
            INNER JOIN Tmp_Group_Cust ON Tmp_Group_Cust.sCust = SH.SH_CUST
            INNER JOIN PWIN175.IM  ON IM.IM_STOCK = SD.SD_STOCK
            INNER JOIN PWIN175.NI  ON NI.NI_NV_EXT_KEY = SL.SL_UID
      WHERE NI.NI_STRENGTH = 3 AND NI.NI_DATE = ST.ST_DESP_DATE AND NI.NI_STOCK = SD_STOCK AND NI.NI_STATUS <> 0
      AND     SH.SH_STATUS <> 3
      --AND     sGroupCust IN (gds_cust_in)
      AND       SH.SH_ORDER = ST.ST_ORDER
      --AND  SD.SD_STOCK = gds_stock_in
      --AND       ST.ST_DESP_DATE >= gds_start_date_in AND ST.ST_DESP_DATE <= gds_new_end_date_in
      AND       RM_ANAL = '22NSWP'
      AND       ST.ST_DESP_DATE >= '01-FEB-2016' AND ST.ST_DESP_DATE <= '29-FEB-2016'
      AND       SD.SD_LAST_PICK_NUM = ST.ST_PICK
      GROUP BY  SH.SH_CUST,SH.SH_ORDER,SH.SH_ADD_DATE,SH.SH_ADDRESS,SH.SH_SUBURB,SH.SH_CITY,SH.SH_STATE,SH.SH_POST_CODE,SH.SH_NOTE_1,SH.SH_NOTE_2,SH.SH_CAMPAIGN, SH.SH_SPARE_STR_4,SH.SH_SPARE_DBL_9,SH.SH_CUST_REF,SH.SH_SPARE_STR_5,
                ST.ST_ADD_DATE,ST.ST_ADD_OP,ST.ST_PICK_PRINT_DATE,ST.ST_DESP_DATE,ST.ST_WEIGHT,ST.ST_PACKAGES,ST.ST_PSLIP,ST.ST_PICK,
                SD.SD_DESC,SD.SD_STOCK,SD.SD_XX_OW_UNIT_PRICE,SD.SD_SELL_PRICE,SD.SD_LINE,SD.SD_EXCL,SD.SD_INCL,SD.SD_QTY_ORDER,SD.SD_QTY_UNIT,SD.SD_XX_PICKLIST_NUM,
                IM.IM_BRAND,IM.IM_OWNED_BY,IM.IM_CUST,IM.IM_XX_COST_CENTRE01,IM.IM_REPORTING_PRICE,   ST.ST_SPARE_INT_1,
                NI.NI_SELL_VALUE,NI.NI_NX_QUANTITY,ST.ST_SPARE_DBL_1,  SD.SD_TAX, SH.SH_SPARE_STR_6,
                --RM.RM_GROUP_CUST,RM.RM_PARENT,
                Tmp_Group_Cust.sGroupCust,RM.RM_NAME,IM.IM_SCALE_LCL,  IM.IM_FINISH,
                SL.SL_PSLIP_QTY,SD.SD_SPARE_STR_4;
