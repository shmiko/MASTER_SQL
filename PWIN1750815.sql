 Select SD_ORDER,','
 ,SD_LINE,','
 ,SD_NOTE_1 AS "SD_NOTE_1",','
 ,SD_SELL_PRICE + (f_calc_freight_fee(SD_SELL_PRICE,TRIM(SD_NOTE_1),'IAG',SD_ORDER)/100)  AS "Calc MU",','
 ,SD_SELL_PRICE   AS "SD_SELL_PRICE",','
 ,SD_COST_PRICE   AS "SD_COST_PRICE",','
 ,f_calc_freight_fee(SD_SELL_PRICE,TRIM(SD_NOTE_1),'IAG',SD_ORDER)
 FROM SD Where SD_ORDER >= '   1740626' AND  SD_ORDER <= '   1740626' AND SD_STOCK LIKE 'COURIER%' AND   SD_SELL_PRICE > 0.1 AND SD_CUST = 'IAG';
 
 
 Select /* csv */ * From TMP_HANDLING_FEES
 
 
 ALTER TABLE customers
  ADD (customer_name varchar2(45),
       city varchar2(40));
       
       
declare
  cursor c_t is select table_name from user_tables where table_name LIKE 'TMP_%' order by table_name;
  szSql varchar2(2048);
begin
  for rec in c_t loop 
    szSql := 'alter table '||rec.table_name||' add (spare3 varchar2(255))';
    dbms_output.put_line(szSql);
    execute immediate szSql;
  end loop;
end;
/


alter table TMP_ADMIN add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_ADMIN_DATA2 add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_ADMIN_DATA_BREAKPRICES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_ADMIN_DATA_CUST add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_ADMIN_DATA_PICKSLIPS add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_ADMIN_DATA_PICK_LINECOUNTS add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_ALL_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_ALL_FREIGHT add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_BATCH_PRICE_SL_STOCK add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_CTN_DESP_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_CTN_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_CTN_IN_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_CUSTOMER_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_CUST_REPORTING add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_DESTROY_ORD_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_EMAIL_ORD_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_FAX_ORD_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_FREIGHT add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_GROUP_CUST add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_GROUP_CUST2 add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_HANDLING_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_HAND_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_IM_LOG_DATA add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_LOCN_CNT_BY_CUST add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_LOG_CNTS add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_LOG_STATS add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_MAN_ORD_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_MISC_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_M_FREIGHT add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_ORD_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_PACKING_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_PAL_CTN_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_PAL_DESP_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_PAL_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_PAL_IN_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_PHONE_ORD_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_PICK_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_SD_FR_DATA add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_SEC_STOR_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_SHRINKWRAP_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_SLOW_STOR_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_STOCK_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_STOR_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_VERBAL_ORD_FEES add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))
alter table TMP_V_FREIGHT add (campaign varchar2(255),spare1 varchar2(255),spare2 varchar2(255),spare3 varchar3(255))


Describe TMP_ALL_FEES

alter table "PWIN175"."TMP_ALL_FEES" rename column "SPARE1" to "IFSSELL"
alter table "PWIN175"."TMP_ALL_FEES" rename column "SPARE2" to "IFSCOST"
alter table "PWIN175"."TMP_ALL_FEES" rename column "SPARE3" to "XXFREIGHT"