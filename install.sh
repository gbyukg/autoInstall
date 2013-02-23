#!/bin/bash
install_method=${1} #git/url
db_name=${2}	#sugarcrm
db_host=${3}	#localhost
db_port=${4}	#50000
db_user=${5}	#db2inst1
db_pwd=${6}		#admin
web_root="/document/gbyukg/www/sugar/"
current_dir=$(pwd)

#从github上获取代码并重构
function get_git()
{
	sugar_name=git_sugarcrm_${master_b}
	git_store=/document/gbyukg/www/git_sugar/Mango/	#git代码库
	build_path=/document/gbyukg/www/sugar/build_path/ #sugarcrm build路径
	cd ${git_store}

	#验证分支是否存在
	if [ $(git branch | grep install_${master_b} | wc -l) == '1' ]; then
		git checkout ibm_current
		git branch -D install_${master_b}
	fi
	echo "fetch分支${master_b}..."
	git fetch upstream ${master_b}
	if [ $? -ne 0 ]; then
		echo 'fetch出错'
		exit 1
	fi
	git checkout -b install_${master_b} upstream/${master_b}
	#合并子分支
	if [ "X${merage_b}" == "X" ]; then
		#git merge upstream/${merge_b}
		echo "合并分支${merge_b}..."
		git pull origin ${merge_b}
		if [ $? -ne 0 ]; then
			echo "merge分支upstream/${merge_b}出错"
			exit 1
		fi
		sugar_name=git_sugarcrm_${master_b}_${merge_b}
	fi
	rm -rf ${build_path}* ${web_root}/${sugar_name}
	cd build/rome
	echo "开始构建..."
	php build.php -clean -cleanCache -flav=ult -ver=6.4.0 -dir=sugarcrm -build_dir=${build_path}
	cd ../../
	echo "复制安装文件到：${web_root}/${sugar_name}"
	cp -r ${build_path}ult/sugarcrm ${web_root}/${sugar_name}
}

#下载指定build版本sugarcrm
function get_url()
{
	#生成的安装文件名
	sugar_name=url_sugarcrm_${sugar_build}
	if [ -e "${sugar_build}" ]; then
		echo '删除原文件'
		rm -rf ${sugar_build}
	fi
	echo "开始下载${sugar_build}.zip..."
	wget -c http://sugjnk01.rtp.raleigh.ibm.com/${sugar_branch}/${sugar_build}.zip

	unzip -d ./url_sugarcrm ${sugar_build}
	#cd ${sugar_build}

	rm -rf ${web_root}/${sugar_name}
	mv url_sugarcrm/SugarUlt-Full-6.4.0 ${web_root}/${sugar_name}
}

#init db
function init_db()
{
	echo "初始化数据库${db_name}..."
	cd ${current_dir}
	./initdb.exp ${db_name}
}

#更新dataloader配置文件
function update_config()
{
	echo "更新dataloader配置文件：${1}/ibm/config.php"
	cat <<HERE > config.php
<?php

\$config = array(

	// DB settings 
	'db' => array(
		'type' => 'db2', // mysql or db2
		'host' => '${db_host}',
		'port' => '${db_port}',
		'username' => '${db_user}',
		'password' => '${db_pwd}',
		'name' => '$db_name',
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
}

#data_loader
function data_loader()
{
	if [ "${install_method}" == "git" ]; then
		cp -r ${git_store}ibm ${web_root}${sugar_name}
		cd ${web_root}${sugar_name}/ibm/dataloaders/
		update_config ${web_root}${sugar_name}ibm/dataloaders
	else
		echo 'url'
	fi
	echo '读取dataloader...'
	php populate_SmallDataset.php
}


if [ "${install_method}" == "git" ]; then
	echo 'install from git...'
	master_b=${7}
	merge_b=${8}
	get_git
elif [ "${install_method}" == "url" ]; then
	sugar_branch=${7}
	sugar_build=${8}
fi

#初始化数据库
init_db

#开始安装
cd ${current_dir}
echo '安装sugarcrm...'
php install.php ${sugar_name} ${db_name}

#dataloader
data_loader

rm ~*
echo "success!!!"
#打开浏览器
chromium-browser http://www.sugar.com/${sugar_name}





