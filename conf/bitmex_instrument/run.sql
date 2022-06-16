create table public.bitmex_instrument (
	"symbol" varchar(6),
	"openInterest" integer,
	"openValue" bigint,
	"markPrice" float,
	"midPrice"float,
	"vwap" float,
	"fundingRate" float,
	"indicativeFundingRate" float,
	"ts" timestamp(0))
 partition by range("ts");

select 'create table jumbo.bitmex_instrument_' ||
                    extract(year from zz) ||
   to_char(extract(month from zz),'fm00') ||
   to_char(extract(day from zz),'fm00') ||
$$ partition of public.bitmex_instrument for values from ('$$ ||
                                     date(zz) ||
                                     $$')$$   ||
                                   $$ to ('$$ ||
           date(date(zz) + interval '1day') ||
                                      $$');$$
    from
    generate_series(date_trunc('day',to_date('20220615','yyyymmdd')),
                    date_trunc('day',to_date('20220705','yyyymmdd')),'1 day') as tt(zz);

/gexec
