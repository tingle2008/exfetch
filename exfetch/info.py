from .utils import rel2abs,whoami
from abc import ABCMeta,abstractmethod
from dataclasses import dataclass,field

import os,re,time
from os.path import exists,isdir

import pprint
pp = pprint.PrettyPrinter(indent=4)

import yaml

@dataclass
class Info():
    directory: str
    confdir:   str = None
    overrides: dict = field(default_factory = dict)
    data:      dict = field(default_factory = dict)
    meta:      dict = field(default_factory = dict)

    def __post_init__(self):
        data = {}
        table = {}


        for yaml_conf in [ self.confdir + "/default.yaml", self.directory + "/run.yaml" ]:
            if not exists(yaml_conf):
                continue

            try:
                with open(yaml_conf,"r") as conf_stream:
                    table = yaml.safe_load ( conf_stream )
            except yaml.YAMLError as exc :
                print("Error in configuration file:", exc)

            #XXX log info:
            print("LOADING", yaml_conf)

            for t1_key in table.keys():
                if t1_key in data:
                    data[t1_key] = data[t1_key]
                else:
                    data[t1_key] = {}

                for t2_key in table[t1_key].keys():
                    data[t1_key][t2_key] = table[t1_key][t2_key]

        dirname = self.directory.split(os.sep)[-1]
        print(dirname)
        if dirname != '.' and dirname != '':
            if 'name' not in data['default']:
                data['default']['name'] = dirname

        finaldata = {}
        for key in data['default']:
            finaldata[key] = data['default'][key]
        pp.pprint(finaldata)
        self.data = finaldata




