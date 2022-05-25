import re,os,pwd,socket

def rel2abs( path ):
    e = re.compile('^/').match(path) 
    if e:
        return path
    return os.getcwd() + "/" +  path

def whoami():
    user = pwd.getpwuid(os.getuid())
    name = '{}@{}'.format(user.pw_name,
                          socket.gethostname())
    return name

