import asyncio,asyncpg
from aiohttp import ClientSession, ClientWebSocketResponse 
import websockets
import re,os,sys,time
import json
from abc import ABCMeta,abstractmethod
from .utils import rel2abs,whoami
from .info import Info

class FetchContext(metaclass = ABCMeta):
    def __init__( self ):
        self.__allFetchers = []
        self.__allObservers = []
        self.__curFetcher = None
        self.__fetcherInfo = None

    def error(self,msg):
        print("error msg is:", msg)
        raise SystemExit(1)

    def addFetcher( self, fetcher ):
        if( fetcher not in self.__allFetchers ):
            self.__allFetchers.append( fetcher )

    def addObserver(self,observer):
        if( oberserver not in self.__allObservers ):
            self.__allObservers.append( observer )

    def _getFetcherInfo(self):
        return(self.__fetcherInfo)

    def changeFetcher(self,fetcher):
        if (fetcher is None):
            return False
        if (self.__curFetcher is None):
            print("初始化为",fetcher.getName())
        else:
            print(self.__curFetcher.getName(),"->", fetcher.getName())

        self.__curFetcher = fetcher
        self.addFetcher(fetcher)
        return True

    def getFetcher(self):
        return self.__curFetcher

    def setFetcherInfo(self, fetcherInfo):
        self.__fetcherInfo = fetcherInfo
        for fetcher in self.__allFetchers:
            if (fetcher.isMatch(fetcherInfo)):
                self.changeFetcher(fetcher)
                fetcher.setInfo(fetcherInfo)

def singleton(cls, *args, **kwargs):
    "构造一个单例的装饰器"
    instance = {}

    def __singleton(*args, **kwargs):
        if cls not in instance:
            instance[cls] = cls(*args, **kwargs)
        return instance[cls]
    return __singleton

class Fetcher(metaclass = ABCMeta):
    def __init__(self, verbose = 0, cwd = None):
        self.cwd      = cwd
        self._loop    = asyncio.get_event_loop()
        self.info    = None

    def getName( self ):
        return self.__class__.__name__

    def getInfo( self ):
        return self.info

    def setInfo( self, fetcherInfo ):
        self.info = fetcherInfo
        self.schema = self.info.data['schema']
        self.dbhost = self.info.data['dbhost']
        self.dbport = self.info.data['dbport']
        self.dbuser = self.info.data['dbuser']
        self.dbpass = self.info.data['dbpass']	
        self.dbname = self.info.data['dbname']
        self.dst_table = self.info.data['dst_table']

    async def setConn(self):
        self.conn = await asyncpg.connect(host=self.dbhost,
									 port=self.dbport,
									 user=self.dbuser,
									 password=self.dbpass)

    async def chkTable(self):
        check_stmt= """
		SELECT EXISTS (
    		SELECT FROM 
        		pg_tables
    	WHERE 
        	schemaname = '{}' AND 
        	tablename  = '{}'
    	);
        """.format(self.schema,self.dst_table)
        print("checking table: {} ".format(self.dst_table))
        res = await self.conn.fetchval(check_stmt)
        if not res:
            print("table {} does not exist!!".format(self.dst_table))
        else:
            print("check table: {} done! ".format(self.dst_table))

    @abstractmethod
    async def tableAppend(self,data):
       pass

    def getName( self ):
        return self.__class__.__name__

    def getInfo( self ):
        return self.info

    @abstractmethod
    def isMatch(self):
        "状态的属性Info是否在当前的状态范围内"
        pass

    @abstractmethod
    def runFetcher(self):
        pass

@singleton
class BinanceFetcher(Fetcher):
    def __init__(self, verbose, cwd):
        super().__init__(verbose ,cwd)
        # XXX: getINFO here and 
        self._session = ClientSession()
        self._ws  = None

    def isMatch(self,fetcherInfo):
        return fetcherInfo.data['exchange'] == 'binance'

    async def tableAppend(self,data):
        d = json.loads(data)
        ins_value = self.info.data['ins_sub_query']
        dst_table = self.info.data['dst_table']
        value_list = []
        value_json = None
        if 'data' not in d :
            print("not data json")
            return
        elif isinstance(d['data'],list): 
            value_json = json.dumps(d['data'])
        else:
            value_list.append(d['data'])
            value_json = json.dumps(value_list)

        jsonb_array_elements_sub_query = """
        select jsonb_array_elements('{}'::jsonb) as o
        """.format(value_json)

        ins_stmt = """
           insert into {} (select {} from ( {} ) as j)
        """.format(dst_table,
                   ins_value, 
                   jsonb_array_elements_sub_query)

        print("executing:", ins_stmt)
        await self.conn.execute(ins_stmt)
        #print(ins_stmt)
        #print(value_json)

    async def wssapiDatabase(self):
        await self.setConn()
        await self.chkTable()

        async with self._session.ws_connect( self.apiurl,
                   						   proxy = self.proxy,
                                           verify_ssl=False) as ws:
            # use subscribe as config unit
            await ws.send_str(self.subscribe)
            async for msg in ws:
                if 'data' in msg.data:
                    await self.tableAppend(msg.data)

    async def wssapiStdout(self):
        async with self._session.ws_connect( self.apiurl,
                   						   proxy = self.proxy,
                                           verify_ssl=False) as ws:
            await ws.send_str(self.subscribe)
            async for msg in ws:
                print(msg.data)

    def runFetcher(self):
        self.api = self.info.data['api']
        self.apitype = self.info.data['apitype']
        self.proxy   = self.info.data['proxy']
        self.subscribe = self.info.data['subscribe']
        self.dst_table = self.info.data['dst_table'] 

        if self.apitype == 'wss':
            self.apiurl = 'wss://{}'.format(self.api)

        if self.dst_table == '':
            self._loop.run_until_complete(self.wssapiStdout())
        else:
            self._loop.run_until_complete(self.wssapiDatabase())

        print("running fetcher api:",self.apiurl)

class ExFetch( FetchContext ):
    def __init__(self,
                directory = None,
                info = None,
                overrides = {},
                meta = None,
                confdir = '/etc/exfetch',
                verbose = 0):
        super().__init__()

        self.cwd = os.getcwd()
        self.directory = rel2abs( re.sub('/$','',directory ) )
        self.overrides = overrides
        self.meta      = meta
        self.confdir   = confdir
        self.verbose   = verbose

        self.info   =  Info( overrides = self.overrides,
                             directory = self.directory,
                             confdir   = self.confdir,
                             meta      = self.meta)

        self.addFetcher(BinanceFetcher(cwd     = self.cwd ,
                                       verbose = self.verbose ))
        self.setFetcherInfo( self.info )

    def run(self):
        fetcher = self.getFetcher()
        fetcher.runFetcher()
        return True


