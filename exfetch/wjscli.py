#!/usr/bin/env python
import asyncio
import websockets
import json,sys
import time
import click

from aiohttp import ClientSession, ClientWebSocketResponse
#from psycopg2 import extras,sql

async def send_request(ws,subs):
    await ws.send_str(subs)

async def call_api(api,subs,count):
    c = count
    ws_session = ClientSession()
    async with ws_session.ws_connect(api) as ws:
        await send_request(ws,subs) 
        async for msg in ws:
            c = c - 1
            print(msg.data)
            if c == 0:
                raise SystemExit(0)

@click.command()
@click.argument('subfile', type=click.File('rb'))

@click.option('--api', prompt='api address',
        help='input api address: e.g. wss://fstream.binance.com/stream')

@click.option('--count', default=2, help='result number.')
@click.option('-v', '--verbose', count = True , help='verbose mode. default off')
def main(api,subfile,count,verbose):
    """
    access wss api and fetch COUNT result out.
    """
    sub_req = subfile.read(1024).decode("utf-8")
    loop = asyncio.get_event_loop()
    loop.run_until_complete(loop.create_task(call_api(api,sub_req,count)))


#if __name__ == '__main__':
#    main()
