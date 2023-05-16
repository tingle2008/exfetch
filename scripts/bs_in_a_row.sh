#!/bin/bash


psql -U trader   << SQL_DOC
with a as (SELECT
  floor(extract(epoch from "EventTime")/60)*60 AS "time",
  sum("Quantity" *  (case when "BMM" then 0 else 1 end)) / sum("Quantity" *  (case when "BMM" then 1 else 0 end)) as lsr,
  sum("Quantity" *  (case when "BMM" then 0 else 1 end)) as "BuyQ",
  sum("Quantity" *  (case when "BMM" then 1 else 0 end)) as "SellQ",
  avg("Price") as "avgPrice"
FROM ts_binance_fut_aggtrade
WHERE "EventTime" > (select max("time") from public.annotations where symbol = 'btcusdt' and exchange='binance_fut') and "EventTime" < now() - interval '10m' and "Symbol" = 'BTCUSDT'  group by 1 order by 1),
b as (select "time",
              case when "lsr" > 2 then 1 when "lsr" < 0.5 then -1 else 0 end as "lsQR",
              "BuyQ",
              "SellQ",
              "avgPrice" from a where "BuyQ" > 10 or "SellQ" > 10),
c as (select "time",
             "lsQR",
             "BuyQ",
             "SellQ",
             "avgPrice",
              row_number() over (order by "time") - row_number() over (partition by "lsQR" order by "time") as "grp"
              from b ),
d as (select max("time") as "time",
      "lsQR",
      count(*) as "runLength",avg("avgPrice") as "@avgPrice",avg("BuyQ") - avg("SellQ") as "avgQ"
      from c group by "lsQR","grp" )

insert into annotations select 
                        to_timestamp("time"), 
						"runLength",
						round(cast("@avgPrice" as numeric),2) , 
						round(cast("avgQ" as numeric), 2) , 
						"lsQR" ,
						'binance_fut' as exchange,
						'btcusdt' as symbol
        from d 
        where "runLength" > 2 and "lsQR" <> 0  order by 1 desc;

with a as (SELECT
  floor(extract(epoch from "EventTime")/60)*60 AS "time",
  sum("Quantity" *  (case when "BMM" then 0 else 1 end)) / sum("Quantity" *  (case when "BMM" then 1 else 0 end)) as lsr,
  sum("Quantity" *  (case when "BMM" then 0 else 1 end)) as "BuyQ",
  sum("Quantity" *  (case when "BMM" then 1 else 0 end)) as "SellQ",
  avg("Price") as "avgPrice"
FROM ts_binance_fut_aggtrade
WHERE "EventTime" > (select max("time") from public.annotations where symbol = 'ethusdt' and exchange='binance_fut') and "EventTime" < now() - interval '10m' and  "Symbol" = 'ETHUSDT'  group by 1 order by 1),
b as (select "time",
              case when "lsr" > 2 then 1 when "lsr" < 0.5 then -1 else 0 end as "lsQR",
              "BuyQ",
              "SellQ",
              "avgPrice" from a where "BuyQ" > 100 or "SellQ" > 100),
c as (select "time",
             "lsQR",
             "BuyQ",
             "SellQ",
             "avgPrice",
              row_number() over (order by "time") - row_number() over (partition by "lsQR" order by "time") as "grp"
              from b ),
d as (select max("time") as "time",
       "lsQR",
        count(*) as "runLength", avg("avgPrice") as "@avgPrice",
        avg("BuyQ") - avg("SellQ") as "avgQ" 
      from c group by "lsQR","grp" )
insert into annotations select to_timestamp("time"), 
                                "runLength",
                                round(cast("@avgPrice" as numeric),2) , 
                                round(cast("avgQ" as numeric), 2) , 
                                "lsQR" ,
                                'binance_fut' as exchange,
                                'ethusdt' as symbol 
        from d 
        where "runLength" > 2 and "lsQR" <> 0  order by 1 desc;

SQL_DOC

