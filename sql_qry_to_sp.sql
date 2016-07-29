			SELECT * 
			FROM TABLE
						(parallel_dump –- this is a pipelined function which helps to create a huge file using UTL
							(
								CURSOR	
													(
									
														SELECT /*+ PARALLEL(s,4)*/
														to_clob(B1)||to_clob(B2)||to_clob(B3)||to_clob(B4) AS cvs  
														FROM 
														(select 
															(A1||…||A200) as B1,
															(A201||…||A400) as B2, 
															(A401||…||A600) as B3,
															(A601||…||A839) as B4 
															from 
															(
																Select blabla from Dual

																Union all 


																select * from anytable


																union all

																select blablaba from DUAL  

																union all

																select blabla from DUAL  

															)

														) s
													),
								'filename',
								'DIRECTORY_NAME'
							)
						) nt;



create or replace procedure my_proc
IS
begin
for rec in 
				(
				--insert sql query here
					SELECT                     *
					FROM TABLE 
								(parallel_dump –- this IS a pipelined FUNCTION which helps TO CREATE a huge file USING UTL 
									( 
										CURSOR
														(
															SELECT /*+ PARALLEL(s,4)*/
															to_clob(B1)
															||to_clob(B2)
															||to_clob(B3)
															||to_clob(B4) AS cvs
																			FROM
																		(SELECT 
																			(A1
																			  ||…
																			  ||A200) AS B1,
																			  (A201
																			  ||…
																			  ||A400) AS B2,
																			  (A401
																			  ||…
																			  ||A600) AS B3,
																			  (A601
																			  ||…
																			  ||A839) AS B4
																			FROM
																			( SELECT blabla FROM Dual
																				UNION ALL
																				SELECT * FROM anytable
																				UNION ALL
																				SELECT blablaba FROM DUAL
																				UNION ALL
																				SELECT blabla FROM DUAL
																			)				
																		) s
														), 
									'filename',
									'DIRECTORY_NAME' 
								)
								) nt
				--finish sql query here
				)
  LOOP
   -- do whatever you want with the data for example:
   dbms_output.put_line('value of col1 ' || rec.col1);
  END LOOP;
END;
