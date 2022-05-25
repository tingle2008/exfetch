from .exfetch import ExFetch
from .utils import whoami
import click

@click.command()
@click.argument('fetchdir', nargs= 1, type=click.Path(exists=True))
@click.option('-v', '--verbose', count = True , help='verbose mode. default off')
@click.option('-s', '--set', 'setstr', help='List of variables to set e.g.: a=b,c=d')

def run(fetchdir,verbose,setstr):

    init_metadata = {'actionlog':
   	                [{'actor': whoami(),
                     'time' : '2022-04-15 16:20:10',
                     'type' : 'fetch',
                   'actions':
                        [{'summary':'fetcher initialiation',
                          'text'   :"fetcher version: ", },],},],}

    overrides = {}
    if setstr:
        seta = setstr.split(",")
        for l in seta:
            k,v = l.split('=',1)
            overrides[k] = v

    ef = ExFetch(directory = fetchdir,
                 verbose = verbose,
                 overrides = overrides,
                 meta = init_metadata)

    ef.run()
