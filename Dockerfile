FROM python:3.10

RUN apt update && apt install gcc -y

WORKDIR /src
ADD . /src
RUN python setup.py install
ADD conf/default.yaml /etc/exfetch/default.yaml
ENTRYPOINT [ "exfetch" ]
