--------------------------------------------------------
--  File created - Thursday-May-07-2015   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Table TBL_ADMINDATA
--------------------------------------------------------

  CREATE GLOBAL TEMPORARY TABLE "PWIN175"."TBL_ADMINDATA" 
   (	"CUSTOMER" VARCHAR2(255 BYTE), 
	"PARENT" VARCHAR2(255 BYTE), 
	"COSTCENTRE" VARCHAR2(255 BYTE), 
	"ORDERNUM" VARCHAR2(255 BYTE), 
	"ORDERWARENUM" VARCHAR2(255 BYTE), 
	"CUSTREF" VARCHAR2(255 BYTE), 
	"PICKSLIP" VARCHAR2(255 BYTE), 
	"PICKNUM" VARCHAR2(255 BYTE), 
	"DESPATCHNOTE" VARCHAR2(255 BYTE), 
	"DESPATCHDATE" VARCHAR2(255 BYTE), 
	"FEETYPE" VARCHAR2(255 BYTE), 
	"ITEM" VARCHAR2(255 BYTE), 
	"DESCRIPTION" VARCHAR2(255 BYTE), 
	"QTY" NUMBER, 
	"UOI" VARCHAR2(255 BYTE), 
	"UNITPRICE" NUMBER, 
	"OW_UNIT_SELL_PRICE" NUMBER, 
	"SELL_EXCL" NUMBER, 
	"SELL_EXCL_TOTAL" NUMBER, 
	"SELL_INCL" NUMBER, 
	"SELL_INCL_TOTAL" NUMBER, 
	"REPORTINGPRICE" NUMBER, 
	"ADDRESS" VARCHAR2(255 BYTE), 
	"ADDRESS2" VARCHAR2(255 BYTE), 
	"SUBURB" VARCHAR2(255 BYTE), 
	"STATE" VARCHAR2(255 BYTE), 
	"POSTCODE" VARCHAR2(255 BYTE), 
	"DELIVERTO" VARCHAR2(255 BYTE), 
	"ATTENTIONTO" VARCHAR2(255 BYTE), 
	"WEIGHT" NUMBER, 
	"PACKAGES" NUMBER, 
	"ORDERSOURCE" NUMBER(*,0), 
	"ILNOTE2" VARCHAR2(255 BYTE), 
	"NILOCN" VARCHAR2(255 BYTE), 
	"COUNTOFSTOCKS" NUMBER, 
	"EMAIL" VARCHAR2(255 BYTE), 
	"BRAND" VARCHAR2(255 BYTE), 
	"OWNEDBY" VARCHAR2(255 BYTE), 
	"SPROFILE" VARCHAR2(255 BYTE), 
	"WAIVEFEE" VARCHAR2(255 BYTE), 
	"COST" VARCHAR2(255 BYTE), 
	"PAYMENTTYPE" VARCHAR2(255 BYTE)
   ) ON COMMIT DELETE ROWS ;
