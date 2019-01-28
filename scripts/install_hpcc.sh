#!/bin/bash

os=

figure_out_extension() {
  os=$(hostnamectl | grep "Operating System" | cut -c21-)
  case $os in
    "CentOS Linux 7"*)
      extension=".el7.x86_64.rpm"
      os=centos
      ;;
    "Amazon Linux 2")
      extension=".el7.x86_64.rpm"
      os=centos
      ;;
    "CentOS Linux 6"*)
      extension=".el6.x86_64.rpm"
      os=centos
      ;;
    "Amazon Linux")
      extension=".el6.x86_64.rpm"
      os=centos
      ;;
    "Ubuntu 14."*)
      extension="trusty_amd64.deb"
      os=ubuntu
      ;;
    "Ubuntu 16."*)
      extension="xenial_amd64.deb"
      os=ubuntu
      ;;
    "Ubuntu 18."*)
      extension="bionic_amd64.deb"
      os=ubuntu
      ;;
    *)
      extension=".el6.x86_64.rpm"
      os=centos
      ;;
  esac
}

install_hpcc() {
  echo "Installing HPCC Systems ${HPCC_VERSION}..." >> /var/log/hpcc-cluster.log
  case $os in
    centos)
      yum -y install /tmp/hpccsystems-platform-community_${build_version}${extension}
      ;;
    ubuntu)
      dpkg -i /tmp/hpccsystems-platform-community_${build_version}${extension}
      apt-get install -f
      ;;
   esac
}

install_tools() {
  echo "Installing tools..." >> /var/log/hpcc-cluster.log
  case $os in
    centos)
      yum -y install httpd-tools
      ;;
    ubuntu)
      apt-get install apache2-utils
      ;;
   esac
}

build_version=${HPCC_VERSION}
version=$(echo ${HPCC_VERSION} | sed "s/-.*//g")
figure_out_extension

echo "Downloading HPCC Systems ${HPCC_VERSION}${extension}..." >> /var/log/hpcc-cluster.log
curl -o /tmp/hpccsystems-platform-community_${build_version}${extension} http://cdn.hpccsystems.com/releases/CE-Candidate-${version}/bin/platform/hpccsystems-platform-community_${build_version}${extension}

install_hpcc
install_tools


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
