#!/bin/bash


date_str=`date +%Y%m%d -d '-120 day'`

for table_name in  bitmex_instrument \
		  bitmex_trade \
		  bitstamp_spot \
		  coinbase_spot_ticker
	  do 
		  echo $table_name
          psql -U trader << DROP_SQL
drop table jumbo.${table_name}_${date_str};
DROP_SQL
	  	  psql -U trader << SQL_DOC

select 'create table if not exists  jumbo.${table_name}_' ||
                            extract(year from zz) ||
   					to_char(extract(month from zz),'fm00') ||
   					to_char(extract(day from zz),'fm00') ||
\$\$ partition of public.${table_name} for values from ('\$\$ ||
                                     date(zz) ||
                                     \$\$')\$\$   ||
                                   \$\$ to ('\$\$ ||
           date(date(zz) + interval '1day') ||
                                      \$\$');\$\$
    from generate_series(date_trunc('day',current_timestamp + interval '1 hour')::date,
                    	 date_trunc('day',current_timestamp + interval '1 hour')::date,'1 day') as tt(zz);

\gexec
SQL_DOC

done

echo "restarting exfetcher services"
sudo /usr/bin/svc -t /service/exfe_deribit /service/exfe_deribit/log  /service/exfe_binance /service/exfe_binance/log  /service/exfetcher_4h /service/exfetcher_4h/log
echo "done"
