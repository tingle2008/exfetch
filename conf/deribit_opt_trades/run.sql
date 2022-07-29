create table public.deribit_opt_trade ( "trade_base" varchar(5),
		 	 		"trade_id" integer,
			 		"timestamp" timestamp,
			 		"tick_direction" smallint ,
			 		"price" float,
			 		"mark_price" float,
			 		"iv" float,
			 		"instrument_name" varchar(20),
			 		"index_price" float,
			 		"direction" varchar(5),
			 		"amount" float)
          partition by range("timestamp")


select 'create table jumbo.deribit_opt_trade_' ||
                    extract(year from zz) ||
   to_char(extract(month from zz),'fm00') ||
$$ partition of jumbo.deribit_opt_trade for values from ('$$ ||
                                     date(zz) ||
                                     $$')$$   ||
                                   $$ to ('$$ ||
           date(date(zz) + interval '1month') ||
                                      $$');$$
    from
            generate_series(date_trunc('month',to_date('20220728','yyyymmdd')),
            date_trunc('month',to_date('20230101','yyyymmdd')),'1 month') as tt(zz);

