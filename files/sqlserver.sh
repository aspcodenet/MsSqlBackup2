#!/bin/sh -xe

# docker run --rm  --name sssss -e sql_database=TestAppProd -e sql_host=165.227.224.194,31561 -e sql_user=sa -e sql_password=Hejsan123   -e AWS_KEY=0031162fe9996230000000001 -e aws_secret=K0036jAL9Tx15Evmpww0Bxe4Fa+G9BE -e s3_host_base=s3.eu-central-003.backblazeb2.com -e cmd=interactive    -it docker.io/library/sqlkube



FILENAME=$(date "+%Y-%m-%d-%H-%M-%S")
sqlcmd -S ${sql_host} -U ${sql_user} -P ${sql_password} -Q "BACKUP DATABASE ${sql_database} TO DISK='/var/opt/mssql/data/${sql_database}$FILENAME'"

POD=$(kubectl get pods --selector=app=mssql -o  jsonpath='{.items[0].metadata.name}')

kubectl cp default/$POD:/var/opt/mssql/data/${sql_database}$FILENAME /opt/src/${sql_database}$FILENAME
kubectl exec $POD --  rm  /var/opt/mssql/data/${sql_database}$FILENAME




#
# main entry point to run s3cmd
#
S3CMD_PATH=/opt/s3cmd/s3cmd

#
# Check for required parameters
#
if [ -z "${aws_key}" ]; then
    echo "The environment variable key is not set. Attempting to create empty creds file to use role."
    aws_key=""
fi

if [ -z "${aws_secret}" ]; then
    echo "The environment variable secret is not set."
    aws_secret=""
    security_token=""
fi

if [ -z "${cmd}" ]; then
    echo "ERROR: The environment variable cmd is not set."
    exit 1
fi

#
# Replace key and secret in the /.s3cfg file with the one the user provided
#
echo "" >> /opt/s3cfg
echo "access_key = ${aws_key}" >> /opt/s3cfg
echo "secret_key = ${aws_secret}" >> /opt/s3cfg
# if [ -z "${security_token}" ]; then
#     echo "security_token = ${aws_security_token}" >> /opt/s3cfg
# fi

#
# Add region base host if it exist in the env vars
#
if [ "${s3_host_base}" != "" ]; then
  sed -i "s/host_base = s3.amazonaws.com/# host_base = s3.amazonaws.com/g" /opt/s3cfg
  echo "host_base = ${s3_host_base}" >> /opt/s3cfg
fi

if [ "${host_bucket}" != "" ]; then
  sed -i "s/host_bucket = %(bucket)s.s3.amazonaws.com/# host_bucket = %(bucket)s.s3.amazonaws.com/g" /opt/s3cfg
  echo "host_bucket = ${host_bucket}" >> /opt/s3cfg
fi


if [ "${bucket_location}" != "" ]; then
  sed -i "s/bucket_location = US/# bucket_location = US/g" /opt/s3cfg
  echo "bucket_location = ${bucket_location}" >> /opt/s3cfg
fi







# Chevk if we want to run in interactive mode or not
if [ "${cmd}" != "interactive" ]; then

  #
  # sync-s3-to-local - copy from s3 to local
  #
  if [ "${cmd}" = "sync-s3-to-local" ]; then
      echo ${src-s3}
      ${S3CMD_PATH} --config=/opt/s3cfg  sync ${SRC_S3} /opt/dest/
  fi

  #
  # sync-local-to-s3 - copy from local to s3
  #
  if [ "${cmd}" = "sync-local-to-s3" ]; then
      ${S3CMD_PATH} --config=/opt/s3cfg sync /opt/src/ ${DEST_S3}
  fi
else
  # Copy file over to the default location where S3cmd is looking for the config file
  cp /opt/s3cfg /root/
fi

#
# Finished operations
#
echo "Finished s3cmd operations"
