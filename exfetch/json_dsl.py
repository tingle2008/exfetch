#!/home/yuting/exfetch/.venv/local/bin/python
import json,sys
import time
import click


@click.command()
@click.argument('jsonfile', type=click.File('rb'))

@click.option('--data', prompt='data payload block key',
        help='payload block key')

@click.option('--table', prompt='table name',
        help='table name')

@click.option('-v', '--verbose', count = True , help='verbose mode. default off')
def main(jsonfile,
         data,
         table,
         verbose):

    d = json.loads(jsonfile.read().decode("utf-8"))
    record = {}
    m_dict = {}

    if data in d:
        if isinstance(d[data], list):
            record = d[data][0]
        else:
            record = d[data]
    else:
        print("{} block was not found.".format(data))

    print(record)
    print(record.keys())
    key_col=",\n".join(record.keys())
    dsl = """
    create table public.{} (id SERIAL,{}
                            )
          partition by range()
    """.format(table,key_col)
    print("dsl output:")
    print(dsl)
