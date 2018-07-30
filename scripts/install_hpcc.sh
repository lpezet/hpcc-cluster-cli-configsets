#!/bin/bash

build_version=${HPCC_VERSION}
version=$(echo ${HPCC_VERSION} | sed "s/-.*//g")
echo "Downloading HPCC Systems..." >> /var/log/hpcc-cluster.log
curl -o /tmp/hpccsystems-platform-community_${build_version}.el6.x86_64.rpm http://cdn.hpccsystems.com/releases/CE-Candidate-${version}/bin/platform/hpccsystems-platform-community_${build_version}.el6.x86_64.rpm
echo "Installing HPCC Systems..." >> /var/log/hpcc-cluster.log
yum -y install /tmp/hpccsystems-platform-community_${build_version}.el6.x86_64.rpm
echo "Installing httpd tools..." >> /var/log/hpcc-cluster.log
yum -y install httpd-tools


# ##########################################
# Backup HPCC Systems Environment
# ##########################################
echo "Backing up HPCC Systems Environment..." >> /var/log/hpcc-cluster.log
if [ ! -f /etc/HPCCSystems/environment.xml.orig ]; then
 cp /etc/HPCCSystems/environment.xml /etc/HPCCSystems/environment.xml.orig
fi
cp /etc/HPCCSystems/environment.xml /etc/HPCCSystems/environment.xml.bak

# ##########################################
# Setting htpasswd for ECLWatch
# ##########################################
user_password=$(openssl rand -base64 16)
echo "$user_password" > /tmp/ecl_watch.pwd
touch /etc/HPCCSystems/.htpasswd
#TODO: use "-B" (bcrypt) option when available on version of htpasswd.
htpasswd -b /etc/HPCCSystems/.htpasswd "hpcc_user" "$user_password"
