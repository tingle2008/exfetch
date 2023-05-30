create table public.ts_deribit_trade ( 
                "amount" float,
                "block_trade_id" text,
		"direction" text,
		"index_price" float,
		"instrument_name" text,
	 	"iv" float,
                "liquidation" text,
		"mark_price" float,
		"price" float,
		"tick_direction" smallint ,
		"timestamp" timestamptz not null,
 		"trade_id"  text,
                "trade_seq" integer
		) tablespace pgdata;

SELECT create_hypertable(
  'ts_deribit_trade',
  'timestamp',
  chunk_time_interval => INTERVAL '7 day'
);
