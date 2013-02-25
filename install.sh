#!/bin/bash
readonly install_method=${1}		#git/url
readonly db_name=${4:-sugarcrm}		#sugarcrm
readonly db_host=${5:-loaclhost}	#localhost
readonly db_port=${6:-50000}		#50000
readonly db_user=${7:-db2inst1}		#db2inst1
readonly db_pwd=${8:-admin}			#admin
readonly web_root="/document/gbyukg/www/sugar/"
readonly current_dir=$(pwd)

#从github上获取代码并重构
function get_git()
{
	echo "选择的下载方式是:GIT"
	sugar_name=git_sugarcrm_${master_b}
	readonly git_store=/document/gbyukg/www/git_sugar/Mango/	#git代码库
	readonly build_path=/document/gbyukg/www/sugar/build_path/ #sugarcrm build路径
	cd ${git_store}

	echo "fetch分支${master_b}..."
	git fetch upstream ${master_b}
	if [ $? -ne 0 ]; then
		echo 'fetch出错'
		exit 1
	fi
	
	#合并子分支
	if [[ "${merge_b}" != "0" && "X${merge_b}" != "X" ]]; then
		#验证分支是否存在
		if [ $(git branch | grep install_${master_b} | wc -l) == '1' ]; then
			git checkout ibm_current
			git branch -D install_${master_b}_${merge_b}
		fi
		git checkout -b install_${master_b}_${merge_b} upstream/${master_b}
		#git merge upstream/${merge_b}
		echo "合并分支${merge_b}..."
		git pull origin ${merge_b}
		if [ $? -ne 0 ]; then
			echo "merge分支upstream/${merge_b}出错"
			exit 1
		fi
		sugar_name=git_sugarcrm_${master_b}_${merge_b}
	else
		#验证分支是否存在
		if [ $(git branch | grep install_${master_b} | wc -l) == '1' ]; then
			git checkout ibm_current
			git branch -D install_${master_b}
		fi
		git checkout -b install_${master_b} upstream/${master_b}
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
	readonly unzip_name="url_sugarcrm"
	echo "选择的下载方式是:URL"
	#生成的安装文件名
	sugar_name=${sugar_build}
	if [ -e "${sugar_build}" ]; then
		echo '删除原文件'
		rm -rf ${sugar_build}
	fi
	echo "开始下载${sugar_build}.zip..."
	wget -c http://sugjnk01.rtp.raleigh.ibm.com/${sugar_branch}/${sugar_build}.zip
	rm -rf ${unzip_name}
	unzip -d ./${unzip_name} ${sugar_build}.zip
	#cd ${sugar_build}

	rm -rf ${web_root}/${sugar_name}
	mv url_sugarcrm/SugarUlt-Full-6.4.0 ${web_root}/${sugar_name}
}

#init db
function init_db()
{
	echo "初始化数据库${db_name}..."
	cd ${current_dir}
	./initdb.exp ${db_name} ${db_pwd}
}

#更新dataloader配置文件
function update_config()
{
	echo "更新dataloader配置文件"
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
		'name' => '${db_name}',
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
		cp -r ${git_store}/ibm ${web_root}${sugar_name}
		cp -r ${git_store}/sugarcrm/tests ${web_root}${sugar_name}
	else
		cp -r ${current_dir}/${unzip_name}/ibm ${web_root}${sugar_name}
	fi
	cd ${web_root}${sugar_name}/ibm/dataloaders/
	update_config
	echo '读取dataloader...'
	php populate_SmallDataset.php
}

#入口
if [[ "X${install_method}" = "X" ]]; then
	echo "请选择获取代码方式(git/url)"
	exit 1
fi
if [ "${install_method}" == "git" ]; then
	readonly master_b=${2}
	readonly merge_b=${3:-0}
	if [[ "${master_b}" == "" ]]; then
		echo "主分支名不能为空"
		exit 0
	fi
	echo 'install from git...'
	get_git
elif [ "${install_method}" == "url" ]; then
	readonly sugar_branch=${2}
	readonly sugar_build=${3}
	if [[ "${sugar_branch}" == "" ]]; then
		echo "URL路径不能为空"
		exit 0
	fi
	if [[ "${sugar_build}" == "" ]]; then
		echo "下载的文件名不能为空"
		exit 0
	fi
	get_url
else
	echo "下载方式错误"
	exit 1
fi

#初始化数据库
init_db

#开始安装
cd ${current_dir}
echo "安装sugarcrm,文件名${sugar_name}..."
php install.php ${sugar_name} ${db_name}

#dataloader
data_loader

cd ${current_dir}
rm ~*
echo "success!!!"
#打开浏览器
chromium-browser http://www.sugar.com/${sugar_name}

