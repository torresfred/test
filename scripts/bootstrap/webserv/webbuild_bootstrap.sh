#! /bin/ksh
# Program Name  :       install_webserver_aws.sh
# Modification History:
# Date          Author          	Description

#set -x
#set -v off

##-----------------------------------------------------------------------------------------##

#Read from tags
instance=`/bin/curl http://169.254.169.254/latest/meta-data/instance-id`
IP=`/bin/curl http://169.254.169.254/latest/meta-data/local-ipv4/`
REGION=`/bin/curl http://169.254.169.254/latest/dynamic/instance-identity/document | /bin/grep region | /bin/awk -F'"' '{print $4}'` 
aws configure set region ${REGION}

# Set psowner and oracle user home directories
userhome=`/bin/cat /etc/passwd | /bin/grep $LOGNAME | awk -F':' '{print $6}'`
oracleuserhome=`/bin/cat /etc/passwd | /bin/grep oracle | awk -F':' '{print $6}'`

# Set variables required in the script
logfolder=$userhome/${instance}
insttags=${logfolder}/insttags
efsmountsinfo=`find ${logfolder}  -name 'efs_mounts*'`
chkhour=`/bin/date '+%H'`
chkdate=`/bin/date '+%d'`
chkmonth=`/bin/date '+%m'`
chkyear=`/bin/date '+%Y'`
clouddt=`/bin/date +%Y%m%d_%H.%M`

# Set variables on the basis of instance tags
service=`/bin/cat $insttags | /bin/grep service | /bin/awk -F '|' '{print $2}'`
type=`/bin/cat $insttags    | /bin/grep type | awk -F '|' '{print $2}'`
TYPE=`/bin/echo $type       | /bin/tr '[:lower:]' '[:upper:]'`
client=`/bin/cat $insttags  | /bin/grep client | awk -F '|' '{print $2}'`
pillar=`/bin/cat $insttags  | /bin/grep pillar | awk -F '|' '{print $2}'`
CLIENT=`/bin/echo $client   | tr '[:lower:]' '[:upper:]'`
TOOLS=`/bin/cat $insttags  | /bin/grep TOOLS | awk -F '|' '{print $2}'`
env=`/bin/cat $insttags  | /bin/grep env | awk -F '|' '{print $2}'`
ENV=`/bin/echo $env    | tr '[:lower:]' '[:upper:]'`
appelb=`/bin/cat $insttags  | /bin/grep appelb | awk -F '|' '{print $2}'`
heapsize=`/bin/cat $insttags  | /bin/grep heapsize | awk -F '|' '{print $2}'`
webprofile=`/bin/cat $insttags  | /bin/grep webprofile | awk -F '|' '{print $2}'`
envname="$client$pillar$env"
ORACLE_SID=`/bin/echo $envname   | /bin/tr '[:lower:]' '[:upper:]'`
buildtype=`/bin/cat $insttags  | /bin/grep "aws:autoscaling:groupName" | /bin/awk -F '|' '{print $1}' | /bin/awk -F ":" '{print $2}'`
tagname=$instance
folder=${chkyear}/${chkmonth}/${chkdate}/${ORACLE_SID}/
logfile=${logfolder}/${service}_${envname}_install.log


#set variables for  webserver domain install using psadmin
DOMAIN_NAME=peoplesoft
WebServer=weblogic
WebServerRootDir=${oracleuserhome}/weblogic
WebServerLoginId=system
WebServerLoginPwd=`aws ssm get-parameters --name "USER_PWD" --with-decryption  --output text  | /bin/awk -F ' ' '{print $4}'`
WebsiteName=$envname
#AppserverHost=$envname
if [ "$TYPE" = "PROD" ];then
   if [ "$pillar" = "gw" ];then
      AppserverHost=$oracle_sid"app"
   else
      AppserverHost=${appelb}
   fi
else
   AppserverHost=$oracle_sid"app"
fi
JSLPort=9000
HTTPPort=8080
HTTPSPort=8443
AuthenticationTokenDomain=`aws ssm get-parameters --name "AUTH_DOMAIN" --with-decryption  --output text  | /bin/awk -F ' ' '{print $4}'`
Webprofile=$webprofile
WebProfUserId=PTWEBSERVER
WebProfUserPwd=`aws ssm get-parameters --name "WEB_PROF_PWD" --with-decryption  --output text  | /bin/awk -F ' ' '{print $4}'`
IntegrGatewayId=Administrator
IntegrGatewayPwd=`aws ssm get-parameters --name "IGW_PWD" --with-decryption  --output text  | /bin/awk -F ' ' '{print $4}'`
AppsrvDomConnPwd=`aws ssm get-parameters --name "DOMAIN_CONN_PWD" --with-decryption  --output text  | /bin/awk -F ' ' '{print $4}'`
RepDir=`cat ${efsmountsinfo} | grep psreports | awk -F':' '{print $5}'`

DOMAIN_HOME="${PS_CFG_HOME}/webserv/${DOMAIN_NAME}"
config="s3://${client}poc-boot-strap/scripts/web/config"
#JAVA_HOME=$oracleuserhome/java
echo "****************************************************************************************************" > $logfile
echo "Installing DOMAIN:$ORACLE_SID for TOOLS:$TOOLS:`date`.............................." >> $logfile



echo "deleting the existing PS_CFG_HOME" >> $logfile
if [ -d ${userhome}/pscfg ];then
   /bin/rm -rf ${userhome}/pscfg 
fi

#if [ "$service" = "web" ];then
#   webserver_build
#else 
#     echo "webserver build can only run on servers with web  as service tag"
#     echo "webserver build can only run on servers with  web as service tag" >> $logfile
#     exit 2
#fi

#echo "$service Install complete on: `date`" >> $logfile
#echo "Please review $logfile for installation details" >> $logfile
#echo "****************************************************************************************************" >> $logfile

#webserver_build ()
#{
#echo "Starting the Webserver Build..............." 
echo "Starting the Webserver Build..............." >> $logfile

#### Creating the Domain
echo "Creating Webserver domain..............." >> $logfile

$PS_HOME/bin/psadmin -w create -d $DOMAIN_NAME -c $WebServer%$WebServerRootDir%$WebServerLoginId%$WebServerLoginPwd%$WebsiteName%$AppserverHost%$JSLPort%$HTTPPort%$HTTPSPort%$AuthenticationTokenDomain%$Webprofile%$WebProfUserId%$WebProfUserPwd%$IntegrGatewayId%$IntegrGatewayPwd%$AppsrvDomConnPwd%$RepDir


File_Updates ()
{

   aws s3 cp ${config}/index.html ${DOMAIN_HOME}/applications/${DOMAIN_NAME}/PORTAL.war/
   aws s3 cp ${config}/robots.txt ${DOMAIN_HOME}/applications/${DOMAIN_NAME}/PORTAL.war/

}

configxml ()
{

Loc_ConfigXML=${DOMAIN_HOME}/config/config.xml
export Loc_ConfigXML

/bin/cp $Loc_ConfigXML $Loc_ConfigXML.vanilla
}

Listen_Address()
{

Listen_Addr_Flg=`/bin/grep "<listen-address" $Loc_ConfigXML | /bin/grep -v "#"`
if [ -z "$Listen_Addr_Flg" ];then
   /bin/sed -i "s/<listen-address\/>/<listen-address>${IP}<\/listen-address>/" $Loc_ConfigXML
   /bin/echo "<listen-address>${IP}</listen-address> already exists in $Loc_ConfigXML" >> $logfile
fi

/bin/dos2unix $Loc_ConfigXML
}

Anon_Admin_lookup ()
{
Anon_Admin_lookup_Flg=`/bin/grep "anonymous-admin-lookup-enabled" $Loc_ConfigXML | /bin/grep -v "#"`

if [ -z "$Anon_Admin_lookup_Flg" ];then
   LINE_DEF_REALM=`/bin/grep -n "default-realm" $Loc_ConfigXML | /bin/awk -F: '{print$1}'`
   ANON_ADMIN_LOOKUP='<anonymous-admin-lookup-enabled>true</anonymous-admin-lookup-enabled>'
   LINE_DEF_REALM=`expr $LINE_DEF_REALM + 1`
   /bin/sed -i "$LINE_DEF_REALM i ${ANON_ADMIN_LOOKUP}" $Loc_ConfigXML
   /bin/sed -i "s/<anonymous-admin-lookup.*$/    <anonymous-admin-lookup-enabled>true<\/anonymous-admin-lookup-enabled>/" $Loc_ConfigXML
   /bin/echo "$ANON_ADMIN_LOOKUP has been added to $Loc_ConfigXML" >> $logfile
else
   /bin/echo "<anonymous-admin-lookup-enabled>true</anonymous-admin-lookup-enabled> already exists in $Loc_ConfigXML" >> $logfile
fi

/bin/dos2unix $Loc_ConfigXML
}

WebAppContainer ()
{

WebAppContainer_Flg=`/bin/grep '<web-app-container>' $Loc_ConfigXML | /bin/grep -v "#"`
if [ -z "$WebAppContainer_Flg" ];then

   WebAppContainer_LOC='<admin-server-name>PIA'
   LINE_WebApp=`/bin/grep -n $WebAppContainer_LOC $Loc_ConfigXML |/bin/grep -v "#" | /bin/awk -F: '{print$1}'`

   /bin/sed -i "$LINE_WebApp i </web-app-container>" $Loc_ConfigXML
   /bin/sed -i "s/<\/web-app-container>/  <\/web-app-container>/" $Loc_ConfigXML

   /bin/sed -i "$LINE_WebApp i <x-powered-by-header-level>NONE</x-powered-by-header-level>"  $Loc_ConfigXML
   /bin/sed -i "s/<x-powered-by-header-level>.*$/    <x-powered-by-header-level>NONE<\/x-powered-by-header-level>/" $Loc_ConfigXML

   /bin/sed -i "$LINE_WebApp i <web-app-container>" $Loc_ConfigXML
   /bin/sed -i "s/<web-app-container>/  <web-app-container>/" $Loc_ConfigXML

   /bin/echo "<web-app-container> entries have been added to $Loc_ConfigXML" >> $logfile
else
   /bin/echo "<web-app-container> entries already exist in $Loc_ConfigXML" >> $logfile
fi

######Weblogic Plug In Enabled ###############################################
Weblogic_Plugin_Flg=`/bin/grep "<weblogic-plugin-enabled>" $Loc_ConfigXML | /bin/grep -v "#"`

if [ -z $Weblogic_Plugin_Flg ];then
   LINE_MSI_FILE_REPLICATION=`/bin/grep -n '<x-powered-by-header-level>' $Loc_ConfigXML | /bin/awk -F: '{print$1}'`
   Weblogic_plugin1='<weblogic-plugin-enabled>true</weblogic-plugin-enabled>'
   Weblogic_plugin2='<weblogic-plugin-enabled>true<\/weblogic-plugin-enabled>'
   LINE_MSI_FILE_REPLICATION=`expr $LINE_MSI_FILE_REPLICATION + 1`
   /bin/sed -i "$LINE_MSI_FILE_REPLICATION i $Weblogic_plugin1" $Loc_ConfigXML
   /bin/sed -i "s/<weblogic-plugin-enabled>.*$/    ${Weblogic_plugin2}/" $Loc_ConfigXML
   /bin/echo " " >> $logfile
   /bin/echo "$Weblogic_plugin1 has been added to $Loc_ConfigXML" >> $logfile
else
   /bin/echo "<weblogic-plugin-enabled>true</weblogic-plugin-enabled> already exists in $Loc_ConfigXML" >> $logfile
fi

/bin/dos2unix $Loc_ConfigXML
}

Log_File_Rotation ()
{

RETVAL=30
Security_Conf_Flg=`/bin/grep '</security-configuration>' $Loc_ConfigXML`
Rotation_Log_on_Startup=`/bin/grep '<rotate-log-on-startup>false</rotate-log-on-startup>' $Loc_ConfigXML`

if [  -z "$Rotation_Log_on_Startup" ];then
   LINE_Log=`/bin/grep -n '</security-configuration>' $Loc_ConfigXML | /bin/awk -F: '{print$1}'`
   LINE_Log=`expr $LINE_Log + 1`
   /bin/sed -i "$LINE_Log i <log>" $Loc_ConfigXML
   /bin/sed -i "s/^<log>/  <log>/" $Loc_ConfigXML
   LINE_Log=`expr $LINE_Log + 1`
   /bin/sed -i "$LINE_Log i <rotation-type>byTime</rotation-type>" $Loc_ConfigXML
   /bin/sed -i "s/^<rotation-type>byTime.*$/    <rotation-type>byTime<\/rotation-type>/" $Loc_ConfigXML
   LINE_Log=`expr $LINE_Log + 1`
   /bin/sed -i "$LINE_Log i <number-of-files-limited>true</number-of-files-limited>" $Loc_ConfigXML
   /bin/sed -i "s/^<number-of-files-limited>true.*$/     <number-of-files-limited>true<\/number-of-files-limited>/" $Loc_ConfigXML
   LINE_Log=`expr $LINE_Log + 1`
   /bin/sed -i "$LINE_Log i <file-count>$RETVAL</file-count>" $Loc_ConfigXML
   /bin/sed -i "s/^<file-count>.*$/    <file-count>$RETVAL<\/file-count>/" $Loc_ConfigXML
   LINE_Log=`expr $LINE_Log + 1`
   /bin/sed -i "$LINE_Log i <rotate-log-on-startup>false</rotate-log-on-startup>" $Loc_ConfigXML
   /bin/sed -i "s/^<rotate-log-on-startup>.*$/    <rotate-log-on-startup>false<\/rotate-log-on-startup>/" $Loc_ConfigXML
   LINE_Log=`expr $LINE_Log + 1`
   /bin/sed -i "$LINE_Log i </log>" $Loc_ConfigXML
   /bin/sed -i "s/^<\/log>/  <\/log>/" $Loc_ConfigXML
   /bin/echo "Log File Rotation added to the ${DOMAIN_NAME} in $Loc_ConfigXML" >> $logfile
else
   /bin/echo "<rotate-log-on-startup>false</rotate-log-on-startup> already exists in $Loc_ConfigXML" >> $logfile
fi

PIA_weblogic_Flg=`/bin/grep -A5 PIA_weblogic.log $Loc_ConfigXML | /bin/grep "<rotation-type>byTime<"`

if [ -z "$PIA_weblogic_Flg" ];then
   LINE_PIAWeblogic=`/bin/grep -n 'PIA_weblogic.log' $Loc_ConfigXML | /bin/awk -F: '{print$1}'`
   LINE_PIAWeblogic=`expr $LINE_PIAWeblogic + 1`
   /bin/sed -i "$LINE_PIAWeblogic i <rotation-type>byTime</rotation-type>" $Loc_ConfigXML
   /bin/sed -i "s/^<rotation-type>byTime.*$/      <rotation-type>byTime<\/rotation-type>/" $Loc_ConfigXML
   LINE_PIAWeblogic=`expr $LINE_PIAWeblogic + 1`
   /bin/sed -i "$LINE_PIAWeblogic i <number-of-files-limited>true</number-of-files-limited>" $Loc_ConfigXML
   /bin/sed -i "s/^<number-of-files-limited>true.*$/      <number-of-files-limited>true<\/number-of-files-limited>/" $Loc_ConfigXML
   LINE_PIAWeblogic=`expr $LINE_PIAWeblogic + 1`
   /bin/sed -i "$LINE_PIAWeblogic i <file-count>$RETVAL</file-count>" $Loc_ConfigXML
   /bin/sed -i "s/^<file-count>.*$/      <file-count>$RETVAL<\/file-count>/" $Loc_ConfigXML
   LINE_PIAWeblogic=`expr $LINE_PIAWeblogic + 1`
   /bin/sed -i "$LINE_PIAWeblogic i <rotate-log-on-startup>false</rotate-log-on-startup>" $Loc_ConfigXML
   /bin/sed -i "s/^<rotate-log-on-startup>.*$/      <rotate-log-on-startup>false<\/rotate-log-on-startup>/" $Loc_ConfigXML
   /bin/echo "Log File Rotation added to the PIA in $Loc_ConfigXML" >> $logfile
else
   /bin/echo "<rotate-log-on-startup>false</rotate-log-on-startup> already exists in $Loc_ConfigXML" >> $logfile

fi

/bin/dos2unix $Loc_ConfigXML
}

setEnvsh ()
{

setEnvsh=${DOMAIN_HOME}/bin/setEnv.sh
/bin/cp $setEnvsh $setEnvsh.vanilla

# Set Heap Size for web server domain
psadmin -w configure -d ${DOMAIN_NAME} -c ${heapsize}/${heapsize}

/bin/sed -i "s/^HOSTNAME=.*$/HOSTNAME=${IP}/" $setEnvsh
/bin/sed -i "s/^ADMINSERVER_HOSTNAME=.*$/ADMINSERVER_HOSTNAME=${IP}/" $setEnvsh

/bin/dos2unix $setEnvsh
}

pskeymangersh ()
{

pskeymanagersh=${DOMAIN_HOME}/piabin/pskeymanager.sh
/bin/cp $pskeymanagersh $pskeymanagersh.vanilla
/bin/sed -i '430,440d' $pskeymanagersh
/bin/echo " " >> $logfile
/bin/echo "Default password change for pskey file disabled in tools: $tools in pskeymanager.sh" >> $logfile

/bin/dos2unix $pskeymanagersh
}


webxml ()
{

PORTAL_webxml=${DOMAIN_HOME}/applications/${DOMAIN_NAME}/PORTAL.war/WEB-INF/web.xml
PSIGW_webxml=${DOMAIN_HOME}/applications/${DOMAIN_NAME}/PSIGW.war/WEB-INF/web.xml

/bin/cp $PORTAL_webxml $PORTAL_webxml.vanilla
/bin/cp $PSIGW_webxml  $PSIGW_webxml.vanilla

/bin/sed -i 's/<session-timeout>.*$/<session-timeout>60<\/session-timeout>/g' $PORTAL_webxml
/bin/sed -i 's/<session-timeout>.*$/<session-timeout>60<\/session-timeout>/g' $PSIGW_webxml

STARTUP_LOC='psft.pt8.psreports'
STARTUP_CODE='<load-on-startup>0</load-on-startup>'
LIN_NUM=`/bin/grep -n $STARTUP_LOC $PORTAL_webxml | /bin/awk -F: '{print$1}'`
LOC_NUM=`expr $LIN_NUM + 5`
/bin/sed -i "$LOC_NUM  i $STARTUP_CODE" $PORTAL_webxml
#/bin/sed -i "s/<load-on-startup>0</load-on-startup>.*$/<load-on-startup>0</load-on-startup>/" $PORTAL_webxml

/bin/echo " " >> $logfile
/bin/echo "The value of <session-timeout> has been updated to 60 in web.xml" >> $logfile
/bin/echo "load-on-startup options added to web.xml" >> $logfile

/bin/dos2unix $PORTAL_webxml
/bin/dos2unix $PSIGW_webxml
}

weblogicxml ()
{

weblogicxml=${DOMAIN_HOME}/applications/${DOMAIN_NAME}/PORTAL.war/WEB-INF/weblogic.xml
/bin/cp $weblogicxml $weblogicxml.vanilla

PSFT_ENV_NAME=`/bin/ls ${DOMAIN_HOME}/applications/${DOMAIN_NAME}/PORTAL.war/WEB-INF/psftdocs | tail -1`


CookieName=$PSFT_ENV_NAME-8080-PORTAL-PSJSESSIONID

/bin/sed -i "s/<param-value>.*PSJSESSIONID.*param-value>/<param-value>${CookieName}<\/param-value>/g" $weblogicxml
/bin/sed -i "s/<cookie-name>.*PSJSESSIONID.*cookie-name>/<cookie-name>${CookieName}<\/cookie-name>/g" $weblogicxml

/bin/cp $weblogicxml $weblogicxml.sci
/bin/echo " " >> $logfile
/bin/echo "$CookieName has been added to weblogic.xml" >> $logfile

/bin/dos2unix $weblogicxml
}

igprop ()
{

igprop=$DOMAIN_HOME/applications/${DOMAIN_NAME}/PSIGW.war/WEB-INF/integrationGateway.properties
/bin/cp $igprop $igprop.vanilla

SFKS_PASSWD='{V1.1}7m4OtVwXFNyLc1j6pZG69Q=='

LINE=ig.fileconnector.password=EncryptedPassword
NUM=`/bin/grep -n $LINE $igprop | /bin/grep -v "#" | /bin/awk -F: '{print$1}'`


if [ ! -z "$NUM" ];then
/bin/sed -i "s/^${LINE}/#${LINE}/" $igprop
fi

SecFileKeyStore=`/bin/grep secureFileKeystorePasswd $igprop | /bin/grep '{V1.1}7m4OtVwXFNyLc1j6pZG69Q=='`

if [ -z "$SecFileKeyStore" ];then
/bin/sed -i "s/^secureFileKeystorePasswd.*$/secureFileKeystorePasswd=${SFKS_PASSWD}/" $igprop
fi

/bin/echo " " >> $logfile
/bin/echo "keystore password encrypted in  integrationGateway.properties" >> $logfile

/bin/sed -i  's/WEB-INF\///' $igprop
/bin/sed -i  's/classes/WEB-INF\/classes/g' $igprop
/bin/sed -i "s/^ig.Gateway.showDetails=false/ig.Gateway.showDetails=true/" $igprop

/bin/dos2unix $igprop
}

site_configprop ()
{

configprop=${DOMAIN_HOME}/applications/${DOMAIN_NAME}/PORTAL.war/WEB-INF/psftdocs/${WebsiteName}/configuration.properties
/bin/cp $configprop $configprop.vanilla

/bin/sed -i "s/^DynamicConfigReload.*$/DynamicConfigReload=1/" $configprop
/bin/sed -i "s/^parallelLoading.*$/parallelLoading=false/" $configprop

/bin/echo " " >> $logfile
/bin/echo "DynamicConfigReload has been set to 1 in configuration.properties" >> $logfile
/bin/echo "DomainConnectionPwd has been  set to standard encrypted password in configuration.properties" >> $logfile
/bin/echo "PTWEBSERVER Password has been  set to standard encrypted password in configuration.properties" >> $logfile

/bin/dos2unix $configprop
}

site_igprop ()
{

site_igprop=${DOMAIN_HOME}/applications/${DOMAIN_NAME}/PSIGW.war/WEB-INF/integrationGateway.properties
/bin/cp $site_igprop $site_igprop.$clouddt
ninthchar=`/bin/echo $WebsiteName | cut -c9-9`

if [ -z $ninthchar ]; then


UpperSite=`/bin/echo $WebsiteName | tr [:lower:] [:upper:]`
NODE_NAME="PSFT_"$UpperSite

PRCSUSER=`aws ssm get-parameters --name "PRCSID" --with-decryption  --output text  | /bin/awk -F ' ' '{print $4}'`
PRCSPWD=`aws ssm get-parameters --name "PRCSPWD" --with-decryption  --output text  | /bin/awk -F ' ' '{print $4}'`
ENCPRCSPWD=`eval passchk ${PRCSPWD}`
ENCDCP=`eval passchk ${AppsrvDomConnPwd}`

piaInstallLog=${DOMAIN_HOME}/piaconfig/properties/piaInstallLog.xml
patch=`/bin/grep -w Product-Version-Info $piaInstallLog`
ToolsRel=`/bin/echo $patch | cut -c31-37`


IGPROP_LOCATE=`/bin/grep -n "Default URL used by the ApplicationMessagingTargetConnector" $site_igprop | /bin/awk -F: '{print$1}'`
IGPROP_LINE1="ig.isc.${NODE_NAME}.serverURL=//$AppserverHost:${JSLPort}"
IGPROP_LINE2="ig.isc.$NODE_NAME.userid=${PRCSUSER}"
IGPROP_LINE3="ig.isc.${NODE_NAME}.password=${ENCPRCSPWD}"
IGPROP_LINE4="ig.isc.${NODE_NAME}.toolsRel=${ToolsRel}"
IGPROP_LINE5="ig.isc.${NODE_NAME}.DomainConnectionPwd=${ENCDCP}"
IGPROP_LINE6="#**********************************************************************"


/bin/sed -i "$IGPROP_LOCATE i $IGPROP_LINE5" $site_igprop
/bin/sed -i "$IGPROP_LOCATE i $IGPROP_LINE4" $site_igprop
/bin/sed -i "$IGPROP_LOCATE i $IGPROP_LINE3" $site_igprop
/bin/sed -i "$IGPROP_LOCATE i $IGPROP_LINE2" $site_igprop
/bin/sed -i "$IGPROP_LOCATE i $IGPROP_LINE1" $site_igprop
/bin/sed -i "$IGPROP_LOCATE i $IGPROP_LINE6" $site_igprop

/bin/echo " " >> $logfile
/bin/echo "Node info for $NODE_NAME is added in $site_igprop" >> $logfile

fi

/bin/dos2unix $site_igprop
}

site_pstoolsprop ()
{

pstools_prop=${DOMAIN_HOME}/applications/${DOMAIN_NAME}/PORTAL.war/WEB-INF/psftdocs/${WebsiteName}/pstools.properties
/bin/cp $pstools_prop $pstools_prop.bkp
/bin/sed -i 's/tuxedo_network_disconnect_timeout.*$/tuxedo_network_disconnect_timeout=1300/' $pstools_prop

/bin/echo " " >> $logfile
/bin/echo "tuxedo_network_disconnect_timeout is set to 1300 in pstools.properties" >> $logfile

/bin/dos2unix $pstools_prop
}
site_weblogicxml ()
{
site_weblogicxml=${DOMAIN_HOME}/applications/${DOMAIN_NAME}/PORTAL.war/WEB-INF/weblogic.xml
/bin/cp $site_weblogicxml.sci $site_weblogicxml

/bin/echo " " >> $logfile
/bin/echo "Cookie Value updated back to CMSC Standards " >> $logfile

/bin/dos2unix $site_weblogicxml
}

passchk ()
{

PASS=$1

$JAVA_HOME/bin/java -Dps_vault=${DOMAIN_HOME}/piaconfig/properties/psvault -cp ${DOMAIN_HOME}/applications/peoplesoft/PSIGW.war/WEB-INF/classes/ psft.pt8.pshttp.PSCipher $PASS > /tmp/epwd

CPASS=`cat /tmp/epwd | cut -d: -f2`
/bin/rm -f /tmp/epwd
/bin/echo $PASS | /bin/grep / > /dev/null
FP=`/bin/echo $CPASS | /bin/awk -F"/" '{print$1}'`
SP=`/bin/echo $CPASS | /bin/awk -F"/" '{print$2}'`
TP=`/bin/echo $CPASS | /bin/awk -F"/" '{print$3}'`
ADJPASS="$FP\/$SP\/$TP"

if [ -z $TP ]; then
   ADJPASS="$FP\/$SP"
fi
if [ -z $SP ]; then
   ADJPASS=$FP
fi
/bin/echo "$ADJPASS"
}


All_Functions ()
{
#set_variable
#install_domain

#webserver configuration
File_Updates
configxml
Listen_Address
Anon_Admin_lookup
WebAppContainer
Log_File_Rotation
setEnvsh
pskeymangersh
webxml
weblogicxml
igprop

#site configuration
#RETVAL=$1
site_configprop
site_igprop
site_weblogicxml
site_pstoolsprop

/bin/echo "Webserver Install complete on: `date`" >> $logfile
/bin/echo "Please review $logfile for installation details" >> $logfile
/bin/echo "*****************************************************************************************" >> $logfile

}
################################################################
#               Execution of functions                         #
################################################################
All_Functions
#$AWS s3 cp $logfile s3://${bucket}/${folder}/

#### start the domain
psadmin -w start -d ${DOMAIN_NAME}



passchk ()
{

PASS=$1

$JAVA_HOME/bin/java -Dps_vault=${DOMAIN_HOME}/piaconfig/properties/psvault -cp ${DOMAIN_HOME}/applications/peoplesoft/PSIGW.war/WEB-INF/classes/ psft.pt8.pshttp.PSCipher $PASS > /tmp/epwd

CPASS=`cat /tmp/epwd | cut -d: -f2`
/bin/rm -f /tmp/epwd
/bin/echo $PASS | /bin/grep / > /dev/null
FP=`/bin/echo $CPASS | /bin/awk -F"/" '{print$1}'`
SP=`/bin/echo $CPASS | /bin/awk -F"/" '{print$2}'`
TP=`/bin/echo $CPASS | /bin/awk -F"/" '{print$3}'`
ADJPASS="$FP\/$SP\/$TP"

if [ -z $TP ]; then
   ADJPASS="$FP\/$SP"
fi
if [ -z $SP ]; then
   ADJPASS=$FP
fi
/bin/echo "$ADJPASS"
}
