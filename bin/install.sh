#!/usr/bin/sh

# ===================================================================
# File:		bin/install.sh
# Project:	ShinyCMS
# Purpose:	Install script
#
# Author:	Denny de la Haye <2019@denny.me>
# Copyright (c) 2009-2019 Denny de la Haye
#
# ShinyCMS is free software; you can redistribute it and/or modify it
# under the terms of either the GPL 2.0 or the Artistic License 2.0
# ===================================================================

# Download and unpack ShinyCMS code
got_git=`which git`
if [ "$got_git" != '' ]; then
  echo '1. Cloning git repository from GitHub...'
  git clone https://github.com/denny/ShinyCMS.git
  cd ShinyCMS
else
  echo '1. Downloading and unpacking code...'
  curl -o ShinyCMS.tar.gz https://github.com/denny/ShinyCMS/archive/v19.5.tar.gz
  tar zxf ShinyCMS.tar.gz
  cd ShinyCMS-19.5
fi

# Install Catalyst and other required Perl modules
echo "\n2. Installing Catalyst and other required Perl modules from CPAN..."
sudo cpan inc::Module::Install Module::Install::Catalyst
perl Makefile.PL
sudo make

# Install MySQL dev libs for your distro
distro=`hostnamectl | grep 'Operating System' | sed -r 's/.*System:\s+(\w+)\s.*/\1/'`
echo "\n3. Installing MySQL dev package for your distro ($distro)..."
if [ "$distro" = 'Ubuntu' ]; then
  sudo apt install libmysqlclient-dev
elif [ "$distro" = 'Debian' ]; then
  sudo apt install libmysqlclient-dev
elif [ "$distro" = 'CentOS' ]; then
  sudo yum install mysql-devel
elif [ "$distro" = 'Red' ]; then
  sudo yum install mysql-devel
else
  echo 'Failed to find distro name'
fi

# Install DBD::mysql module (skipping tests, because they need a lot of setup)
echo "\n4. Installing DBD::mysql from CPAN..."
sudo cpan -T -i DBD::mysql

# Create database user
echo "\n5. Creating database and database user..."
sudo mysql -uroot -e 'create database if not exists shinycms character set utf8 collate utf8_general_ci'
sudo mysql -uroot -e "create user if not exists 'shinyuser'@'localhost' identified by 'shinypass'"
sudo mysql -uroot -e "grant all privileges on shinycms.* to 'shinyuser'@'localhost'"

# Insert data
if [ "$SHINYCMS_DEMO" != '' ]; then
  echo "\n6. Setting database up for demo site..."
  ./bin/database/build-with-demo-data
else
  echo "\n6. Setting database up for new (empty) site..."
  ./bin/database/build
fi

echo "\n7. Finished installing ShinyCMS!"
echo "\nYou may find it helpful to read docs/Getting-Started next."
