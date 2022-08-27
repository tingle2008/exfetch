#!/bin/bash

BEGIN_TIME=20220906
END_TIME=20221005


for table_name in binance_fut_aggtrade \
		  binance_fut_all_mark_price \
		  bitmex_instrument \
		  bitmex_trade \
		  bitstamp_spot \
		  coinbase_spot_ticker
	  do 
		  echo $table_name

	  	  psql -U trader   << SQL_DOC

select 'create table jumbo.${table_name}_' ||
                    extract(year from zz) ||
   to_char(extract(month from zz),'fm00') ||
   to_char(extract(day from zz),'fm00') ||
\$\$ partition of public.${table_name} for values from ('\$\$ ||
                                     date(zz) ||
                                     \$\$')\$\$   ||
                                   \$\$ to ('\$\$ ||
           date(date(zz) + interval '1day') ||
                                      \$\$');\$\$
    from
    generate_series(date_trunc('day',to_date('$BEGIN_TIME','yyyymmdd')),
                    date_trunc('day',to_date('$END_TIME','yyyymmdd')),'1 day') as tt(zz);

\gexec
SQL_DOC

done
