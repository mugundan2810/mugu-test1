#!bin/bash

#[Stamps the file name with a date]
export TS=`date +%m-%d-%y-%H%M`
export CDATE=`date +%m-%d-%y`
export CTIME=`date +%H_%M`

SPATH=$(dirname `which $0`)
source $SPATH/logins

export SUB="Backup Logs from $HOSTNAME"
export HTML=$SPATH/msg.html
export LOG=/opt/backup-logs/
#[Generating HTML file with Client Name for emailing]
printf "
<html>
Team <br>
Please verify backup logs for below said clients <br>
`ls  $LOG | sed s/*/p/  | sed 's/.\{4\}$//'` <br>
</html>" > $HTML

# DB Info
export DUMP_PATH=/mnt/mysqlbackup1
export MYSQLPATH=/var/lib/mysql/

#[Source and S3 Bucket ]
export SRC=/opt/

#[S3 Location for Data Backup]
export S3DATA=s3://$S3_BUCKET/data/

#[Client name]
export CLIENTS=clients.txt


#[Creating Client txt file]
if [ ! -f $CLIENTS ]
then
    echo "Creating TXT file"
    touch clients.txt
fi

#[Creating Backup-Logs directory if does not exist]
if [ ! -d $LOG ]
then
    echo "Creating backup log directory"
    mkdir -p $LOG
    mkdir -p "$LOG"archive
fi

#[Creating MySQL Dump directory if does not exist]
if [ ! -d $DUMP_PATH  ]
then
    echo "Creating directory $DUMP_PATH ..." 
    mkdir -p $DUMP_PATH
fi

#[Update more IP if GET access requireded for S3 content example "x.x.x.x/32"]

printf '{
        "Version": "2008-10-17",
        "Id": "S3PolicyId1",
        "Statement": [
                {
                        "Sid": "PutObject",
                        "Effect": "Allow",
                        "Principal": {
                                "AWS": "*"
                        },
                        "Action": "s3:PutObject",
                        "Resource": "arn:aws:s3:::'$S3_BUCKET'/*"
                },
                {
                        "Sid": "IPDeny",
                        "Effect": "Deny",
                        "Principal": {
                                "AWS": "*"
                        },
                        "Action": "s3:GetObject",
                        "Resource": "arn:aws:s3:::'$S3_BUCKET'/*",
                        "Condition": {
                                "NotIpAddress": {
                                        "aws:SourceIp": ['$IPs']
                                }
                        }
                }
        ]
}' > $SPATH/policy.json

export CNT=`/usr/bin/aws s3api list-buckets | grep $S3_BUCKET | wc -l`

if [[ $CNT == 0 ]]
then
    echo "$S3_BUCKET doesn\'t exist creating..."
    aws s3api create-bucket --bucket $S3_BUCKET  --region us-east-1 --acl public-read
fi
    aws s3api put-bucket-policy --bucket $S3_BUCKET --policy file://$SPATH/policy.json

