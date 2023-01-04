create table public.deribit_book_summary_options (
    "volume" float,
    "underlying_price" float,
    "underlying_index" varchar(20),
    "quote_currency"   varchar(8),
    "price_change"     float,
    "open_interest"    float,
    "mid_price"        float,
    "mark_price"       float,
    "low"              float,
    "last"             float,
    "interest_rate"    float,
    "instrument_name"  varchar(20),
    "high"             float,
    "estimated_delivery_price" float,
    "creation_timestamp"    timestamp,
    "bid_price"         float,
    "base_currency"     varchar(8),
    "ask_price"         float
    ) partition by range("creation_timestamp");

select 'create table jumbo.deribit_book_summary_options_' ||
                    extract(year from zz) ||
   to_char(extract(month from zz),'fm00') ||
$$ partition of public.deribit_book_summary_options for values from ('$$ ||
                                     date(zz) ||
                                     $$')$$   ||
                                   $$ to ('$$ ||
           date(date(zz) + interval '1month') ||
                                      $$');$$
    from
            generate_series(date_trunc('month',to_date('20230104','yyyymmdd')),
            date_trunc('month',to_date('20230204','yyyymmdd')),'1 month') as tt(zz);
