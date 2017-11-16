#!/bin/bash



mountz() {
src=$1
mpath=$2
mount ${src}:/  -t nfs  -o nfsvers=4.1,intr  ${mpath}
}

AZ=`/bin/curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone/`

CMSHOMEPATH="/cmshomedirs"
SCRIPTSPATH="/scripts"



[[ $AZ == us-east-1a ]] && SCRIPTSRC="itsscripts-e1a.ec2.internal"   #10.125.4.91
[[ $AZ == us-east-1c ]] && SCRIPTSRC="itsscripts-e1c.ec2.internal"   #10.125.5.79
[[ $AZ == us-east-1d ]] && SCRIPTSRC="itsscripts-e1d.ec2.internal"   #10.125.8.137
[[ $AZ == us-east-1e ]] && SCRIPTSRC="itsscripts-e1e.ec2.internal"   #10.125.11.79
[[ $AZ == us-east-1a ]] && CMSHOMESRC="cmshomedirs-e1a.ec2.internal" #10.125.4.136
[[ $AZ == us-east-1c ]] && CMSHOMESRC="cmshomedirs-e1c.ec2.internal" #10.125.5.138
[[ $AZ == us-east-1d ]] && CMSHOMESRC="cmshomedirs-e1d.ec2.internal" #10.125.8.11
[[ $AZ == us-east-1e ]] && CMSHOMESRC="cmshomedirs-e1e.ec2.internal" #10.125.11.57

mountz $CMSHOMESRC $CMSHOMEPATH
mountz $SCRIPTSRC  $SCRIPTSPATH
