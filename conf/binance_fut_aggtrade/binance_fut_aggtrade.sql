create table public.binance_fut_aggtrade( "EventTime" timestamp,
                                    	 "Symbol" varchar(16),
                                    	 "AggTradeId" bigint,
                                    	 "Price" double precision,
                                    	 "Quantity" double precision,
                                    	 "FirstTid" bigint,
                                    	 "LastTid" bigint,
                                    	 "TradeTime" timestamp,
                                         "BMM" bool )
            partition by range ("EventTime");


-- TODO: 目前只有3个月表继承,未来如果运行时间足够长需要继续添加.            

-- create table by sql string.
select 'create table jumbo.binance_fut_aggtrade_' ||
                    extract(year from zz) ||
   to_char(extract(month from zz),'fm00') ||
   to_char(extract(day from zz),'fm00') ||
$$ partition of public.binance_fut_aggtrade   for values from ('$$ ||
                                     date(zz) ||
                                     $$')$$   ||
                                   $$ to ('$$ ||
           date(date(zz) + interval '1day') ||
                                      $$');$$
    from
    generate_series(date_trunc('day',to_date('20220524','yyyymmdd')),
	 	    date_trunc('day',to_date('20220605','yyyymmdd')),'1 day') as tt(zz);

\gexec

create index binance_fut_aggtrade_etx on binance_fut_aggtrade using brin("EventTime")

