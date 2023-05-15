create table public.ts_binance_fut_all_mark_price( "EventTime" timestamptz not null,
                                    	 "Symbol" text,
                                    	 "MarkPrice" double precision,
                                    	 "IndexPrice" double precision,
                                    	 "EstSettlePrice" double precision,
                                    	 "FundingRate" double precision,
                                    	 "NextFundingTime" timestamptz ) 
				TABLESPACE pgdata;


create index binance_fut_all_mark_price_etx on binance_fut_all_mark_price using brin("EventTime")

