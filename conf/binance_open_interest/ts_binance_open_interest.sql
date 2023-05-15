create table public.ts_binance_open_interest ("Symbol" text,
			  		   "openInterest" float,
			  		   "LastUpdateTime" timestamptz);


SELECT create_hypertable(
  'ts_binance_open_interest',
  'LastUpdateTime',
  chunk_time_interval => INTERVAL '1 day'
);

