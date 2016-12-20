select sol.cust_id, d.[AC NO], d.NAMES, sol.so_id 'OrderNo', sol.line_item_no, sol.PO_NO 'PO', oby.CUST_RECIP_ID 'Order By', sto.CUST_RECIP_ID 'Ship To', bto.CUST_RECIP_ID 'Bill To', inventory_code, item_description, order_qty 'Order Qty', bo_qty 'BackOrder Qty',
isnull(pack_qty,0) 'Package Qty',sol.status_id, st.STATUS_NAME 'Status', sol.created_date, sol.modified_date, sop.unit_price, sop.discount , (order_qty * sop.UNIT_PRICE) - sop.discount 'Total Price', sol.pick_id, isnull((select SUM(ACTUAL_CHARGE) from PACKAGE where pick_id = sol.PICK_ID),0) 'Total Package Charge', (select count(PACKAGE_ID) from PACKAGE where pick_id = sol.PICK_ID) 'Package Count', ad.field_name 'Order Variable', ad.FIELD_VALUE 'Variable Value'
from so_line_item sol
left outer join so_line_item_price sop on sop.so_id = sol.so_id and sop.line_item_no = sol.line_item_no 
left outer join FFSTATUS st on st.STATUS_ID = sol.STATUS_ID 
left outer join so_addl ad on ad.so_id = sol.so_id 
left outer join CUSTOMER c on c.cust_id = sol.cust_id 
left outer join debtor d on d.[dataflex recnum one] = c.debtor_recnum 
left outer join SALES_ORDER s on s.SO_ID = sol.SO_ID 
left outer join RECIPIENT oby on s.ORDER_BY_ID = oby.RECIP_ID 
left outer join RECIPIENT sto on s.SHIP_TO_ID = sto.RECIP_ID 
left outer join RECIPIENT bto on s.BILL_TO_ID = bto.RECIP_ID 
where (sol.CREATED_DATE >= '2016-12-01' and sol.CREATED_DATE <= '2016-12-31') 
AND sol.SO_ID = 2227
order by sol.CUST_ID, sol.SO_ID
