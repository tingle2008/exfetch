#!/bin/bash


date_str=`date +%Y%m%d -d '-120 day'`

for table_name in deribit_book_summary_future \
		          deribit_book_summary_options \
                  deribit_trade
	  do 
		  echo $table_name
	  	  psql -U trader << SQL_DOC

select 'create table if not exists  jumbo.${table_name}_' ||
                     		extract(year from zz) ||
    				to_char(extract(month from zz),'fm00') ||
\$\$ partition of public.${table_name} for values from ('\$\$ ||
                                     date(zz) ||
                                     \$\$')\$\$   ||
                                   \$\$ to ('\$\$ ||
           date(date(zz) + interval '1month') ||
                                      \$\$');\$\$
    from
            generate_series(date_trunc('month',current_timestamp + interval '1 hour'),
            date_trunc('month',current_timestamp + interval '1 hour'),'1 month') as tt(zz);

\gexec
SQL_DOC

done

echo "restarting exfetcher services"
sudo /usr/bin/svc -t /service/exfetcher_uniq /service/exfetcher_uniq/log
echo "done"
