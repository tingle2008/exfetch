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

create index binance_fut_aggtrade_etx on binance_fut_aggtrade using brin("EventTime")

