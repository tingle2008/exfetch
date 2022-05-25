create table public.binance_fut_all_mark_price( id SERIAL,
                                    	 "EventTime" timestamp,
                                    	 "Symbol" varchar(16),
                                    	 "MarkPrice" double precision,
                                    	 "IndexPrice" double precision,
                                    	 "EstSettlePrice" double precision,
                                    	 "FundingRate" double precision,
                                    	 "NextFundingTime" timestamp )
            partition by range ("EventTime");


-- TODO: 目前只有3个月表继承,未来如果运行时间足够长需要继续添加.            

-- create table by sql string.
select 'create table jumbo.binance_fut_all_mark_price_' ||
                    extract(year from zz) ||
   to_char(extract(month from zz),'fm00') ||
   to_char(extract(day from zz),'fm00') ||
$$ partition of public.binance_fut_all_mark_price  for values from ('$$ ||
                                     date(zz) ||
                                     $$')$$   ||
                                   $$ to ('$$ ||
           date(date(zz) + interval '1day') ||
                                      $$');$$
    from
    generate_series(date_trunc('day',to_date('20220522','yyyymmdd')),
	 	    date_trunc('day',to_date('20220601','yyyymmdd')),'1 day') as tt(zz);

create index binance_fut_all_mark_price_idx on binance_fut_all_mark_price(id);
create index binance_fut_all_mark_price_etx on binance_fut_all_mark_price using brin("EventTime")

