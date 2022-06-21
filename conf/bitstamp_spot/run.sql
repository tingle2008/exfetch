create table public.bitstamp_spot (
	"ts" timestamp(0),
	"symbol" varchar(6),
	"amount" float,
	"price" float,
	"type" smallint
 	) partition by range("ts");


select 'create table jumbo.bitstamp_spot_' ||
                    extract(year from zz) ||
   to_char(extract(month from zz),'fm00') ||
   to_char(extract(day from zz),'fm00') ||
$$ partition of public.bitstamp_spot   for values from ('$$ ||
                                     date(zz) ||
                                     $$')$$   ||
                                   $$ to ('$$ ||
           date(date(zz) + interval '1day') ||
                                      $$');$$
    from
    generate_series(date_trunc('day',to_date('20220619','yyyymmdd')),
                    date_trunc('day',to_date('20220705','yyyymmdd')),'1 day') as tt(zz);
