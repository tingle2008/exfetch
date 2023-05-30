create table public.ts_deribit_book_summary_options (
    "volume" float,
    "underlying_price" float,
    "underlying_index" text,
    "quote_currency"   text,
    "price_change"     float,
    "open_interest"    float,
    "mid_price"        float,
    "mark_price"       float,
    "low"              float,
    "last"             float,
    "interest_rate"    float,
    "instrument_name"  text,
    "high"             float,
    "estimated_delivery_price" float,
    "creation_timestamp"    timestamptz not null,
    "bid_price"         float,
    "base_currency"     text,
    "ask_price"         float
    ) tablespace pgdata;


SELECT create_hypertable(
  'ts_deribit_book_summary_options',
  'creation_timestamp'
);
