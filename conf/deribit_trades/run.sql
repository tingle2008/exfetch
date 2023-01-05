
create table public.deribit_trade ( 
                    "amount" float,
                    "block_trade_id" varchar(50),
			 		"direction" varchar(5),
			 		"index_price" float,
			 		"instrument_name" varchar(20),
			 		"iv" float,
                    "liquidation" char(3),
			 		"mark_price" float,
			 		"price" float,
			 		"tick_direction" smallint ,
			 		"timestamp" timestamp,
		 	 		"trade_id"  varchar(20),
                    "trade_seq" integer
			 		) partition by range("timestamp");


