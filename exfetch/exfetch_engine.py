import asyncio,asyncpg
from aiohttp import ClientSession, ClientWebSocketResponse 
import websockets
import re,os,sys,time
import json
from abc import ABCMeta,abstractmethod
from .utils import rel2abs,whoami
from .info import Info
import pdb 


import pprint
pp = pprint.PrettyPrinter(indent=4)

class Message:
    def __init__(self, name, data = None):
        """"""
        self.name = name
        self.data = data

class FetchEngine(metaclass = ABCMeta):
    def __init__( self ):
        self._loop  = asyncio.get_event_loop()
        self._queue = asyncio.Queue()
        self.__allInjector = None
        self.__fetcherInfo = None

    def error(self,msg):
        print("error msg is:", msg)
        raise SystemExit(1)

    def _getFetcherInfo(self):
        return(self.__fetcherInfo)

    def getAllFetchers(self):
        return self.__allFetchers

    def setFetcherInfo(self, fetcherInfo):
        self.__fetcherInfo = fetcherInfo
        for fetcher in self.__allFetchers:
            fetcher.setInfo(fetcherInfo)

class fTask( metaclass = ABCMeta ):
    def __init__(self, name , task_info = None):
        self._session = ClientSession()
        self.task_info   = task_info
        self.name        = name


    @abstractmethod
    async def runit(self):
        pass

class FetchTask(fTask):
    def __init__(self, name, task_info):
        super().__init__(name ,task_info)
        self.intval = self.task_info['intval']
        self.apiurl = self.task_info['api']

    def data_to_value(self,msg):
        '''
        return value is python built-in data
        NOT json data.
        if json payload is NULL
        '''
        data = json.loads(msg)
        jdata_wanted = []

        if 'jdata_wanted' in self.task_info:
            jdata_wanted = self.task_info['jdata_wanted']

        if self.task_info['jdata'] == '':
            for jk in jdata_wanted:
                if jk not in data:
                    print("Warning:RAW DATA Missing jk key:",jk)
                    return ''
            return(data)
        else:
            if self.task_info['jdata'] not in data:
                return ''
            else:
                for jk in jdata_wanted:
                    if isinstance(data[self.task_info['jdata']],list):
                        # 1 rec as sample.
                        if jk not in data[self.task_info['jdata']][0]:
                            print("Warning:JDATA[0] Missing jk key:",jk)
                            return ''
                    elif jk not in data:
                        print("Warning:JDATA Missing jk key:",jk)
                        return ''
                return(data[self.task_info['jdata']])
 
    async def fetch_rest_api(self,apiurl,subscribe):

        value_list = []
        for sub in subscribe:
            params = {}
            suburi = list(sub.keys())[0]     
            furl = '{}{}'.format(apiurl,suburi)
            method = sub[suburi]
            for k in sub.keys():
                if k != suburi:
                    params[k] = sub[k]
            if method == 'GET':
                async with self._session.get(furl,params = params) as resp:
                    msg = await resp.text()
                    ret_value = self.data_to_value(msg)
                    if ret_value == '':
                        continue
                    else:
                        if isinstance(ret_value,list):
                            for value in ret_value:
                                value_list.append( value )
                        else:
                            value_list.append(ret_value)

        return json.dumps(value_list)

    async def fetch_wss_api(self,ws):

        value_list = []
        msg = await ws.receive()
        ret_value = self.data_to_value(msg.data)
        if ret_value != '':
            value_list = ret_value

        return json.dumps(value_list)


    async def runit(self,q):

        if self.task_info['apitype'] == 'wss':
            async with self._session.ws_connect(self.apiurl,
                                                proxy = self.task_info['proxy'],
                                                verify_ssl = False) as ws:

                await ws.send_str(self.task_info['subscribe'])
                while True:
                    msg = await ws.receive()
                    m = Message(self.name, msg.data)
                    q.put_nowait(m)

        elif self.task_info['apitype'] == 'rest':
            while True:
                data = await self.fetch_rest_api(self.apiurl,
                                                 self.task_info['subscribe'])
                if data == '[]':
                    await asyncio.sleep(self.intval)
                    continue
                m = Message(self.name,data)
                q.put_nowait(m)
                await asyncio.sleep(self.intval)

class InjectTask(fTask):
    def __init__(self, task_info = None):
        self.info   = task_info
        self.tbl_cache = {}

        for n in task_info:
            self.schema = task_info[n]['schema']
            self.dbhost = task_info[n]['dbhost']
            self.dbport = task_info[n]['dbport']
            self.dbuser = task_info[n]['dbuser']
            self.dbpass = task_info[n]['dbpass']
            self.dbname = task_info[n]['dbname']
            break

    async def setConn(self):
        self.conn = await asyncpg.connect(host=self.dbhost,
					     				 port=self.dbport,
						    			 user=self.dbuser,
						    			 password=self.dbpass)

    async def tableExist(self,schema,table):

        if table in self.tbl_cache:
            return self.tbl_cache[table]
        
        check_stmt= """
		SELECT EXISTS (
    		SELECT FROM 
        		pg_tables
    	WHERE 
        	schemaname = '{}' AND 
        	tablename  = '{}'
    	);
        """.format(schema,table)
        print("checking table: {} ".format(table))
        res = await self.conn.fetchval(check_stmt)
        if not res:
            print("table {} does not exist!!".format(table))
            self.tbl_cache[table] = False
            return False
        else:
            print("check table: {} done! ".format(table))
            self.tbl_cache[table] = True
            return True

    async def tableAppend(self,message):

        value_list = []
        value_json = None
        d = json.loads(message.data)
        d2 = {}
        dst_table = message.name

        if 'ins_sub_query' not in self.info[message.name]:
            print('{} just say: {}'.format(message.name,message.data))
            return
        ins_value = self.info[message.name]['ins_sub_query']

        if 'dst_table' in self.info[message.name]:
            dst_table = self.info[message.name]['dst_table']

        dst_table_exist = await self.tableExist( self.schema, dst_table )

        if not dst_table_exist:
            print('{} does not exist,just say:{}'.format(message.name,message.data))
            return
            
        jdata = self.info[message.name]['jdata'] 

        if self.info[message.name]['apitype'] == 'rest':
            value_json = message.data
        elif jdata not in d :
            print("warning: w/o: json payload [data].")
            return
        elif isinstance(d[jdata],list): 
            value_json = json.dumps(d[jdata])
        else:
            value_list.append(d[jdata])
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

    async def runit(self,q):
        await self.setConn()

        while True:
            m = await q.get()
            await self.tableAppend(m)
            q.task_done()
        return

class ExFetch( FetchEngine ):
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
        self.tasks     = []

        self.info   =  Info( overrides = self.overrides,
                             directory = self.directory,
                             confdir   = self.confdir,
                             meta      = self.meta )

    def _createFetchTask( self, name, task_info ):
        t = FetchTask(name, task_info)
        task = asyncio.create_task( t.runit(self._queue) )
        self.tasks.append(task)

    def _createInjectTask(self,ta_info):
        i = InjectTask(ta_info)
        task = asyncio.create_task(i.runit(self._queue))
        self.tasks.append(task)

    async def main(self): 
        for task_name in self.info.data:
            self._createFetchTask(task_name,self.info.data[task_name])

        self._createInjectTask(self.info.data)
        await self._queue.join()
        await asyncio.gather(*self.tasks, return_exceptions=True)
        print('====')


    def run(self):
        #asyncio.run(self.main(),debug=True)
        asyncio.run(self.main())

