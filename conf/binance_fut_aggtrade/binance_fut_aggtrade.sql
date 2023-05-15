CREATE TABLE ts_binance_fut_aggtrade (
  "EventTime" TIMESTAMPTZ NOT NULL,
  "Symbol" TEXT NOT NULL,
  "AggTradeId" BIGINT,
  "Price" DOUBLE PRECISION,
  "Quantity" DOUBLE PRECISION,
  "FirstTid" BIGINT,
  "LastTid" BIGINT,
  "TradeTime" TIMESTAMPTZ,
  "BMM" BOOLEAN
) TABLESPACE pgdata;

-- chunk time interval set to 1day
SELECT create_hypertable(
  'ts_binance_fut_aggtrade',
  'EventTime',
  chunk_time_interval => INTERVAL '1 day'
);

-- create index binance_fut_aggtrade_etx on binance_fut_aggtrade using brin("EventTime")

