#!/bin/bash
install_method=${1}
db_name=${2}
db_host=${3}
db_port=${4}
db_user=${5}
db_pwd=${6}
web_root="/document/gbyukg/www/sugar"

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
	git fetch upstream ${master_b}
	if [ $? -ne 0 ]; then
		echo 'fetch出错'
		exit 1
	fi
	git checkout -b install_${master_b} upstream/${master_b}
	#合并子分支
	if [ "X${merage_b}" -ne "X" ]; then
		#git merge upstream/${merge_b}
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
	echo "初始化数据库..."
	./initdb.exp ${dbname}
}

#data_loader
function data_loader()
{
	echo 'dataloader...'
	
}


if [ "${install_method}" == "git" ]; then
	master_b=${7}
	merge_b=${8}
	get_git
elif [ "${install_method}" == "url" ]; then
	sugar_branch=${7}
	sugar_build=${8}
fi

#init_db

#开始安装
#php install.php ${sugar_name} ${dbname}

#echo ${install_method}
#echo ${db_name}
#echo ${db_host}
#echo ${db_port}
#echo ${db_user}
#echo ${db_pwd}
#echo ${master_b}
#echo ${merge_b}
echo $@
echo "success!!!"





