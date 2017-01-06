SELECT Count(DISTINCT NA_STOCK) AS CountOfStocks, IL_LOCN, r.sGroupCust,
                        CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                          ELSE 'F- Shelves'
                          END AS "Note",NULL,NULL,NULL,NULL
              FROM IL --INNER JOIN NE  ON IL_LOCN = NI_LOCN
              INNER JOIN PWIN175.NA ON NA_EXT_KEY = IL_UID --ON NA_STOCK = IM_STOCK
             -- INNER JOIN PWIN175.IL  ON IL_UID = NA_EXT_KEY
              INNER JOIN PWIN175.NE  ON NE_ACCOUNT  = NA_ACCOUNT AND NA_EXT_TYPE = '1210067'
              INNER JOIN IM ON IM_STOCK = NA_STOCK
              LEFT JOIN Dev_Group_Cust r ON r.sCust = IM_CUST
              WHERE IM_ACTIVE = 1
              AND NE_AVAIL_ACTUAL >= 1
              AND NE_STATUS <> 3
              AND r.sGroupCust IS NOT NULL
              GROUP BY r.sGroupCust,IL_LOCN, IM_CUST,IL_NOTE_2