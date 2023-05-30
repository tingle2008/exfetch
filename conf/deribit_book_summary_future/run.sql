create table public.ts_deribit_book_summary_future (
    "volume_usd" float,
    "volume_notional" float,
    "volume" float,
    "quote_currency"   text,
    "price_change"     float,
    "open_interest"    float,
    "mid_price"        float,
    "mark_price"       float,
    "low"              float,
    "last"             float,
    "instrument_name"  text,
    "high"             float,
    "estimated_delivery_price" float,
    "creation_timestamp"    TIMESTAMPTZ not null,
    "underlying_price" float,
    "bid_price"         float,
    "base_currency"     text,
    "ask_price"         float
    ) tablespace pgdata;

SELECT create_hypertable(
  'ts_deribit_book_summary_future',
  'creation_timestamp',
  chunk_time_interval => INTERVAL '7 day'
);


