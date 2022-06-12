create table public.bitmex_trade_xbtusd ("tt" timestamp,
                                         "side" varchar(5) ,
                                         "size" integer,
                                         "price" float,
                                         "grossValue" float,
                                         "homeNotional" float)
     partition by range("tt")

select 'create table jumbo.bitmex_trade_xbtusd_' ||
                    extract(year from zz) ||
   to_char(extract(month from zz),'fm00') ||
   to_char(extract(day from zz),'fm00') ||
$$ partition of public.bitmex_trade_xbtusd   for values from ('$$ ||
                                     date(zz) ||
                                     $$')$$   ||
                                   $$ to ('$$ ||
           date(date(zz) + interval '1day') ||
                                      $$');$$
    from
    generate_series(date_trunc('day',to_date('20220609','yyyymmdd')),
                    date_trunc('day',to_date('20220705','yyyymmdd')),'1 day') as tt(zz);

/gexec
