FROM python:alpine

RUN apk update
RUN apk add git ca-certificates
RUN pip install python-dateutil

RUN git clone https://github.com/s3tools/s3cmd.git /opt/s3cmd
RUN ln -s /opt/s3cmd/s3cmd /usr/bin/s3cmd

WORKDIR /opt

ADD ./files/mine /opt/s3cfg
ADD ./files/main.sh /opt/main.sh
ADD ./files/sqlserver.sh /opt/sqlserver.sh

RUN apk add --no-cache mysql-client mariadb-connector-c

# Main entrypoint script
RUN chmod 777 /opt/main.sh
RUN chmod 777 /opt/sqlserver.sh

# Folders for s3cmd optionations
RUN mkdir /opt/src
RUN mkdir /opt/dest

RUN dos2unix /opt/sqlserver.sh

WORKDIR /
CMD ["sh", "/opt/sqlserver.sh"]
