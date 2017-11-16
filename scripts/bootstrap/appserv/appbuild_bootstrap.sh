hhhh! /bin/ksh
# Program Name  :       install_webserver_aws.sh
# Modification History:
# Date          Author          	Description

#set -x
#set -v off

##-----------------------------------------------------------------------------------------##


appserver_build ()
{
#echo "Starting the Appserver Build..............." 
echo "Starting the Appserver Build..............." >> $logfile

#### Creating the Domain
echo "Creating Appserver domain..............." >> $logfile
$PS_HOME/bin/psadmin -c create -d $ORACLE_SID -t medium
#$PS_HOME/bin/psadmin -c create -d $ORACLE_SID -t medium -s $ORACLE_SID%ORACLE%$UserId%$UserPswd%$ORACLE_SID%" "%people%$ConnectPswd%" "%$DomainConnectionPwd%ENCR

#DBNAME%DBTYPE%OPR_ID%OPR_PSWD%DOMAIN_ID%ADD_TO_PATH%DB_CNCT_ID%DB_CNCT_PSWD%SERVER_NAME%DOM_CONN_PWD%(NO)ENCR

#### Editing psappsrv.cfg
echo "Editing psappsrv.cfg..............." >> $logfile
cp -p /scripts/app/config/${TOOLS}/psappsrv.cfg $HOME/pscfg/appserv/$ORACLE_SID
sed -i "s/^DBName=.*/DBName=$ORACLE_SID/g" $HOME/pscfg/appserv/$ORACLE_SID/psappsrv.cfg
sed -i "s/^UserId=.*/UserId=$UserId/g" $HOME/pscfg/appserv/$ORACLE_SID/psappsrv.cfg
sed -i "s/^UserPswd=.*/UserPswd=$UserPswd/g" $HOME/pscfg/appserv/$ORACLE_SID/psappsrv.cfg
sed -i "s/^ConnectPswd=.*/ConnectPswd=$ConnectPswd/g" $HOME/pscfg/appserv/$ORACLE_SID/psappsrv.cfg
sed -i "s~^DomainConnectionPwd=.*~DomainConnectionPwd=$DomainConnectionPwd~g" $HOME/pscfg/appserv/$ORACLE_SID/psappsrv.cfg
sed -i "s/^Domain ID=.*/Domain ID=$ORACLE_SID/g" $HOME/pscfg/appserv/$ORACLE_SID/psappsrv.cfg

#DEFAULT Values in a ubb file ##################################################################################################
#{PUBSUB} Do you want the Publish/Subscribe servers configured (y/n)? [n]:
#{QUICKSRV} Move quick PSAPPSRV services into a second server (PSQCKSRV) (y/n)? [n]:
#{QUERYSRV} Move long-running queries into a second server (PSQRYSRV) (y/n)? [n]:
#{JOLT} Do you want JOLT configured (y/n)? [y]:
#{JRAD} Do you want JRAD configured (y/n)? [n]:
#{WSL} Do you want WSL configured (y/n)? [n]:
#{DBGSRV} Do you want to enable PeopleCode Debugging (PSDBGSRV) (y/n)? [n]:
#{RENSRV} Do you want Event Notification configured (PSRENSRV) (y/n)? [y]:
#{MCF} Do you want MCF servers configured (y/n)? [n]:
#{PPM} Do you want Performance Collators configured (PSPPMSRV) (y/n)? [n]:
#{ANALYTICSRV} Do you want Analytic servers configured (PSANALYTICSRV) (y/n) [y]:
#{DOMAIN_GW} Do you want Domains Gateway (External Search Server) configured (y/n)? [n]:
#{SERVER_EVENTS} Do you want Push Notifications configured (y/n)? [n]:
####################################################################################################

#### Editing psappsrv.ubx
echo "Editing psappsrv.ubx..............." >> $logfile

if [ "$analytic" = "true" ];then

   echo "ANALYTICSRV  is enabled for the Domain: $ORACLE_SID" >> $logfile
else
   echo "ANALYTICSRV  is disabled for the Domain: $ORACLE_SID" >> $logfile
   sed -i "s/{ANALYTICSRV} Do you want Analytic servers configured (PSANALYTICSRV) (y\/n) \[y\]:/{ANALYTICSRV} Do you want Analytic servers configured (PSANALYTICSRV) (y\/n) \[n\]:/g" $HOME/pscfg/appserv/$ORACLE_SID/psappsrv.ubx

fi

if [ "$ren" = "true" ];then
   echo "PSRENSRV is enabled for the Domain: $ORACLE_SID" >> $logfile
else
   echo "PSRENSRV is disabled for the Domain: $ORACLE_SID" >> $logfile
   sed -i "s/{RENSRV} Do you want Event Notification configured (PSRENSRV) (y\/n)? [y]:/{RENSRV} Do you want Event Notification configured (PSRENSRV) (y\/n)? [n]:/g" $HOME/pscfg/appserv/$ORACLE_SID/psappsrv.ubx 

fi

if [ "$type" = "nprd" ];then
   echo "DBGSRV  handler enabled for the $type Domain: $ORACLE_SID" >> $logfile
   sed -i "s/{DBGSRV} Do you want to enable PeopleCode Debugging (PSDBGSRV) (y\/n)? [n]:/{DBGSRV} Do you want to enable PeopleCode Debugging (PSDBGSRV) (y\/n)? [y]:/g" $HOME/pscfg/appserv/$ORACLE_SID/psappsrv.ubx 
fi

if [[ "$ren" = "true" || "$pubsub" = "true" ]];then

   echo "PUBSUB/WSL/JOLT/PSAPPRV handlers enabled & QCKSRV & QRYSRV disabled  for the Domain: $ORACLE_SID" >> $logfile
   sed -i "s/{WSL} Do you want WSL configured (y\/n)? \[n\]:/{WSL} Do you want WSL configured (y\/n)? \[y\]:/g" /$HOME/pscfg/appserv/$ORACLE_SID/psappsrv.ubx
   sed -i "s/{PUBSUB} Do you want the Publish\/Subscribe servers configured (y\/n)? \[n\]:/{PUBSUB} Do you want the Publish\/Subscribe servers configured (y\/n)? \[y\]:/g" $HOME/pscfg/appserv/$ORACLE_SID/psappsrv.ubx
   sed -i "s/{QUERYSRV} Move long-running queries into a second server (PSQRYSRV) (y\/n)? \[n\]:/{QUERYSRV} Move long-running queries into a second server (PSQRYSRV) (y\/n)? \[n\]:/g" $HOME/pscfg/appserv/$ORACLE_SID/psappsrv.ubx
   if [ "$type" = "prd" ];then
      echo "QUICKSRV  handlers enabled for the $type Domain: $ORACLE_SID" >> $logfile
      sed -i "s/{QUICKSRV} Move quick PSAPPSRV services into a second server (PSQCKSRV) (y\/n)? \[n\]:/{QUICKSRV} Move quick PSAPPSRV services into a second server (PSQCKSRV) (y\/n)? \[y\]:/g" $HOME/pscfg/appserv/$ORACLE_SID/psappsrv.ubx
   fi 

fi 
if [[ "$ren" != "true"  &&  "$pubsub" != "true" ]];then
    echo "QUERYSRV  handlers enabled for the $type Domain: $ORACLE_SID" >> $logfile
    sed -i "s/{QUERYSRV} Move long-running queries into a second server (PSQRYSRV) (y\/n)? \[n\]:/{QUERYSRV} Move long-running queries into a second server (PSQRYSRV) (y\/n)? \[y\]:/g" $HOME/pscfg/appserv/$ORACLE_SID/psappsrv.ubx
fi


#### configure the domain
echo "configure the domain..............." >> $logfile
cd $HOME/pscfg/appserv
psadmin -c configure -d $ORACLE_SID

#### start the domain
#psadmin -c boot -d $ORACLE_SID
}


prcs_build ()
{
echo "Starting the Prcs server Build..............." >> $logfile

#### Creating the Domain
echo "Creating the Domain..............." >> $logfile
yes n |psadmin -p create -d $ORACLE_SID -t unix -s
#no n |psadmin -p create -d $ORACLE_SID -t unix -s -ps
#DBNAME,DBTYPE,PRCSSERVER,OPR_ID,OPR_PSWD,DB_CNCT_ID,DB_CNCT_PSWD,SERVER_NAME,LOGOUTDIR,SQRBIN,ADD_TO_PATH,DOM_CONN_PWD,(NO)ENCRYPT

#### Editing psprcs.cfg
echo "Editing psprcs.cfg..............." >> $logfile
cp -p /scripts/app/config/${TOOLS}/psprcs.cfg $HOME/pscfg/appserv/prcs/$ORACLE_SID
echo 1
sed -i "s/^DBName=.*/DBName=$ORACLE_SID/g" $HOME/pscfg/appserv/prcs/$ORACLE_SID/psprcs.cfg
echo 2
sed -i "s/^UserId=.*/UserId=$UserId/g" $HOME/pscfg/appserv/prcs/$ORACLE_SID/psprcs.cfg
echo 3
sed -i "s/^UserPswd=.*/UserPswd=$UserPswd/g" $HOME/pscfg/appserv/prcs/$ORACLE_SID/psprcs.cfg
echo 4
sed -i "s/^ConnectPswd=.*/ConnectPswd=$ConnectPswd/g" $HOME/pscfg/appserv/prcs/$ORACLE_SID/psprcs.cfg
echo 5
echo $DomainConnectionPwd
sed -i "s~^DomainConnectionPwd=.*~DomainConnectionPwd=$DomainConnectionPwd~g" $HOME/pscfg/appserv/prcs/$ORACLE_SID/psprcs.cfg

#### configure the domain
echo "configure the domain..............." >> $logfile
psadmin -p configure -d $ORACLE_SID

#### start the domain
#psadmin -p start -d $ORACLE_SID
}



#Read from tags
instance=`/bin/curl http://169.254.169.254/latest/meta-data/instance-id`
logfolder=/appl/psowner/${instance}
insttags=${logfolder}/insttags

chkhour=`/bin/date '+%H'`
chkdate=`/bin/date '+%d'`
chkmonth=`/bin/date '+%m'`
chkyear=`/bin/date '+%Y'`
clouddt=`/bin/date +%Y%m%d_%H.%M`

service=`/bin/cat $insttags | /bin/grep service | /bin/awk -F '|' '{print $2}'`
client=`/bin/cat $insttags  | /bin/grep client | /bin/awk -F '|' '{print $2}'`
CLIENT=`/bin/echo $client   | /bin/tr '[:lower:]' '[:upper:]'`
type=`/bin/cat $insttags    | /bin/grep type | /bin/awk -F '|' '{print $2}'`
pillar=`/bin/cat $insttags    | /bin/grep pillar| /bin/awk -F '|' '{print $2}'`
env=`/bin/cat $insttags    | /bin/grep env | /bin/awk -F '|' '{print $2}'`
ren=`/bin/cat $insttags    | /bin/grep ren | /bin/awk -F '|' '{print $2}'`
pubsub=`/bin/cat $insttags    | /bin/grep pubsub | /bin/awk -F '|' '{print $2}'`
buildtype=`/bin/cat $insttags  | /bin/grep "aws:autoscaling:groupName" | /bin/awk -F '|' '{print $1}' | /bin/awk -F ":" '{print $2}'`
if [ "$buildtype" = "autoscaling" ];then
   tagname=$instance
else
   tagname=`/bin/cat $insttags | /bin/grep Name | /bin/awk -F '|' '{print $2}'`
fi

envname="$client$pillar$env"
ORACLE_SID=`/bin/echo $envname   | /bin/tr '[:lower:]' '[:upper:]'`
folder=${chkyear}/${chkmonth}/${chkdate}/${ORACLE_SID}/

bucket=${client}"-logs"
logfile=${logfolder}/${service}_${envname}_install.log
echo "****************************************************************************************************" > $logfile
echo "Installing DOMAIN:$ORACLE_SID for TOOLS:$TOOLS:`date`.............................." >> $logfile



#read the passwords from ssm parameter store
UserId=$CLIENT"PRCS"
UserPswd=`aws ssm get-parameters --name "PRCSPWD_ENCRYPT" --with-decryption  --output text  | /bin/awk -F ' ' '{print $4}'`
ConnectPswd=`aws ssm get-parameters --name "APPSRVR_CONN_PWD_ENCRYPT" --with-decryption  --output text  | /bin/awk -F ' ' '{print $4}'`
DomainConnectionPwd=`aws ssm get-parameters --name "DOMAIN_CONN_PWD_ENCRYPT" --with-decryption  --output text  | /bin/awk -F ' ' '{print $4}'`
#UserPswd="NCRT15#R"
#ConnectPswd="peop1e"
#DomainConnectionPwd="domainpwd123"
#echo "$UserId:$UserPswd:$ConnectPswd:$service"

echo "deleting the existing PS_CFG_HOME" >> $logfile
if [ -d /appl/psowner/pscfg ];then
   /bin/rm -rf /appl/psowner/pscfg 
fi
echo "Creating $PS_CUST_HOME" >> $logfile
if [ ! -d /custom/${oracle_sid} ];then
   /bin/mkdir  /custom/${oracle_sid} 
fi

if [ "$service" = "app" ];then
   appserver_build
elif [ "$service" = "prcs" ];then
   prcs_build
elif [[ "$service" != "prcs" || "$service" != "app" ]];then
     echo "The $service is not valid tag" 
     echo "The $service is not valid tag" >> $logfile
     exit 2
fi

echo "$service Install complete on: `date`" >> $logfile
echo "Please review $logfile for installation details" >> $logfile
echo "****************************************************************************************************" >> $logfile
