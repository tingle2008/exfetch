# exfetch 交易所订阅管理

##  CLI


- exfetch  <confdir>
- wss_json_out : 从交易所 wss api中按照 json_case 中的 request 进行订阅.
wss_json_out.py --api wss://fstream.binance.com/stream  json_case/binance_subscribe_fullMarketMarkPrice.json > a.out
- json_dsl 
convert json out to postgresql dsl
./json_dsl.py  data.out  --data data  --table binance_fut_all_mark_price


## 
