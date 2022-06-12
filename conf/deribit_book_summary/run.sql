create table public.deribit_book_summary_main_option (
    "volume" float,
    "underlying_price" float,
    "underlying_index" varchar(20),
    "open_interest" float,
    "mark_price" float,
    "instrument_name" varchar(32),
    "creation_timestamp" timestamp,
    "base_currency" varchar(4)) partition by range("creation_timestamp")


select 'create table jumbo.deribit_book_summary_main_option_' ||
                    extract(year from zz) ||
   to_char(extract(month from zz),'fm00') ||
$$ partition of jumbo.deribit_book_summary_main_option for values from ('$$ ||
                                     date(zz) ||
                                     $$')$$   ||
                                   $$ to ('$$ ||
           date(date(zz) + interval '1month') ||
                                      $$');$$
    from
            generate_series(date_trunc('month',to_date('20220601','yyyymmdd')),
            date_trunc('month',to_date('20230101','yyyymmdd')),'1 month') as tt(zz);

