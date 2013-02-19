#!/bin/bash
#完整参数列表
#./init.sh ibm_published_builds_r053 latest sugarcrm 127.0.0.1 50000 db2inst1 admin
host=${4:-127.0.0.1}
port=${5:-50000}
username=${6:-db2inst1}
pwd=${7:-admin}
dbname=${3:-sugarcrm}

#url地址后半部分
#sugar_build 要下载的文件名
#dbname 数据库名字
if [ $# \< 3 ]; then
	echo '至少输入三个参数(sugar_branch,sugar_build,dbname)'
	exit 1
fi
sugar_branch=$1
sugar_build=$2
if [ -e "${sugar_build}" ]; then
	echo '删除原文件'
	rm -rf ${sugar_build}
fi
echo "开始下载${sugar_branch}/"
wget -c http://sugjnk01.rtp.raleigh.ibm.com/${sugar_branch}/${sugar_build}.zip

unzip -d ./${sugar_build} ${sugar_build}
cd ${sugar_build}
#变更名称
if [ "${sugar_build}" == "latest"  ]; then
	sugar_build=$(date +%Y-%m-%d)
fi
rm -rf /document/gbyukg/www/sugar/SugarUlt-Full-6.4.0_${sugar_build}
mv SugarUlt-Full-6.4.0/ /document/gbyukg/www/sugar/SugarUlt-Full-6.4.0_${sugar_build}

#init db
echo "init db"
if [[ "${dbname}" = "" ]]
then
        echo "Error: Pleas tell me the database name!"
        echo "USAGE: ${0} databaseName"
        echo "CAUTION: This script will drop the database you specified and recreate it!"
        exit 1
fi
../initdb.exp ${dbname}
../install.php SugarUlt-Full-6.4.0_${sugar_build} ${dbname}

#dataloader
#host=${1:-127.0.0.1}
#port=${2:-50000}
#username=${3:-db2inst1}
#pwd=${4:-admin}
#dbname=${5:-sugarcrm}
cd ibm/dataloaders
cat <<HERE > config.php
<?php

\$config = array(

	// DB settings 
	'db' => array(
		'type' => 'db2', // mysql or db2
		'host' => '${host}',
		'port' => '${port}',
		'username' => '${username}',
		'password' => '${pwd}',
		'name' => '$dbname',
	),
	
	// default bean field/values used by Utils_Db::createInsert()
	'bean_fields' => array(
		'created_by' => '1',
		'date_entered' => '2012-01-01 00:00:00',
		'modified_user_id' => '1',
		'date_modified' => '2012-01-01 00:00:00',
	),

	// sugarcrm
	'sugarcrm' => array(
		// full path of the installed sugarcrm instance
		'directory' => '/srv/www/htdocs/build/dev/ult/sugarcrm',
	),

);
HERE
echo 'dataloader'
php populate_SmallDataset.php $dbname
