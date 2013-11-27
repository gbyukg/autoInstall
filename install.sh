#!/usr/bin/env bash

readonly WEB_DIR="/document/gbyukg/www/sugar"
readonly GIT_DIR="/document/gbyukg/www/mango"
readonly BUILD_DIR="/document/gbyukg/www/sugar/build_path"
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly INITDB_PATH="./"
readonly KEY="internal sugar user 20100224"
readonly SITE_URL="http://www.sugar.com/SugarUlt-Full-6.4.0"
readonly SITE_USER="admin"
readonly SITE_PWD="admin"
readonly DB_USER="db2inst1"
readonly DB_PWD="admin"
readonly DB_HOST="localhost"
readonly DB_PORT="50000"

db_name=""
mas_remote="upstream"
fet_remote="origin"
mas_branch=""
fet_branch=""
install_meth=""
install_name=""
star="********************"

err_hand()
{
  [[ X"$?" == X"0" ]] || {
    echo "${1}, 查看日志文件" && exit 1
  }
}

cus_echo()
{
  echo ""
  echo "${star}${1}${star}"
}

get_db_name()
{
  if [ -z ${db_name} ]; then
    [[ "X${install_meth}" == "XGIT"  ]] && db_name="gitsugar" || db_name="urlsugar"
  fi
}

gen_install_name()
{
  install_name="${1}_${2}"
  [[ "X0" != "X${3}" ]] && install_name="${install_name}_${3}"
}

pre_git()
{
  echo ""
  echo "选择的是GIT安装方式"
  echo ""
  cd ${GIT_DIR}

  install_branch_name="install_${install_name}"

  {
    git show-branch ${install_branch_name}>/dev/null && 
    {
      git checkout ibm_current && cus_echo "删除已有分支 : ${install_branch_name}" && git branch -D ${install_branch_name}
    } 2>>${SCRIPT_DIR}/install.log && err_hand "错了！！！！！！！！！！"
  }

  cus_echo "fetch远程代码 : ${mas_remote}" && git fetch ${mas_remote} && cus_echo "创建新分支 : ${install_name}(基于远程分支${mas_remote}/${mas_branch})" && git checkout -b "install_${install_name}" ${mas_remote}/${mas_branch} && {
    [[ -z ${fet_branch} || "X0" == "X${fet_branch}" ]] ||
      {
        cus_echo "合并远程分支分支:${fet_remote}" && git pull --no-edit --stat --summary ${fet_remote} ${fet_branch}
      }
  }
  err_hand "创建分支失败"

  cus_echo "构建代码 -> ${BUILD_DIR}"
  {
    rm -rf ${BUILD_DIR}/*
    rm -rf ${WEB_DIR}/${install_name}
  }>/dev/null 2>&1
  cd ${GIT_DIR}/build/rome
  php build.php -clean -cleanCache -flav=ult -ver=6.4.0 -dir=sugarcrm -build_dir=${BUILD_DIR} && cp -r ${BUILD_DIR}/ult/sugarcrm ${WEB_DIR}/${install_name}
}

pre_url()
{
  echo ""
  echo "选择的是URL安装方式"
  echo ""
}

install()
{
  # 初始化数据库
  time init_db

  cus_echo "开始安装"
  cd ${SCRIPT_DIR}

  cus_echo "安装初始化"
  curl -o install.html -D cookies.cook http://localhost/${install_name}/install.php >/dev/null 2>&1
  sleep 3

  curl -o install.html -b cookies.cook -d "language=en_us&current_step=0&goto=Next" http://localhost/${install_name}/install.php >&/dev/null 2>&1
  sleep 3

  cus_echo "第一步"
  curl -o install.html -b cookies.cook -d "current_step=1&goto=Next" http://localhost/${install_name}/install.php  >&/dev/null 2>&1
  sleep 3

  cus_echo "第一.二步"
  curl -o install.html -b cookies.cook -d "checkInstallSystem=true&to_pdf=1&sugar_body_only=1" http://localhost/${install_name}/install.php >&/dev/null 2>&1
  sleep 3
  
  cus_echo "第二步"
  curl -o install.html -b cookies.cook -d "setup_license_accept=on&current_step=2&goto=Next" http://localhost/${install_name}/install.php >&/dev/null 2>&1
  sleep 3

  cus_echo "第三步"
  curl -o install.html -b cookies.cook -d "setup_license_key=${KEY}&install_type=custom&current_step=3&goto=Next" http://localhost/${install_name}/install.php >&/dev/null 2>&1
  sleep 3
  
  cus_echo "第四步"
  curl -o install.html -b cookies.cook -d "setup_db_type=ibm_db2&current_step=4&goto=Next" http://localhost/${install_name}/install.php >&/dev/null 2>&1
  sleep 3
  
  
  cus_echo "check database"
  curl -o install.html -b cookies.cook -d "checkDBSettings=true&to_pdf=1&sugar_body_only=1&setup_db_database_name=${db_name}&setup_db_port_num=${DB_PORT}&setup_db_host_name=${DB_HOST}&setup_db_admin_user_name=${DB_USER}&setup_db_admin_password=${DB_PWD}&demoData=no" http://localhost/${install_name}/install.php >&/dev/null 2>&1
  sleep 3
  
  
  cus_echo "第五步"
  curl -o install.html -b cookies.cook -d "checkDBSettings=true&setup_db_drop_tables=false&goto=Next&setup_db_database_name=${db_name}&setup_db_host_name=${DB_HOST}&setup_db_prot_num=&setup_db_create_sugarsales_user=&setup_db_admin_user_name=${DB_USER}&setup_db_admin_password_entry=${DB_PWD}&setup_db_admin_password=${DB_PWD}&demoData=no&current_step=5" http://localhost/${install_name}/install.php >&/dev/null 2>&1
  sleep 3
  
  
  cus_echo "第六步"
  curl -o install.html -b cookies.cook -d "current_step=6&goto=Next&setup_site_url=${SITE_URL}&setup_system_name=SugarCRM&setup_site_admin_user_name=${SITE_USER}&setup_site_admin_password=${SITE_PWD}&setup_site_admin_password_retype=${SITE_PWD}" http://localhost/${install_name}/install.php >&/dev/null 2>&1
  sleep 3
  
  
  cus_echo "第七步"
  curl -o install.html -b cookies.cook -d "current_step=7&goto=Next&setup_site_sugarbeet_anonymous_stats=yes&setup_site_session_path=&setup_site_log_dir=&setup_site_guid=" http://localhost/${install_name}/install.php >&/dev/null 2>&1

  cus_echo "第八步"
  curl -o install.html -b cookies.cook -d "current_step=8&goto=Next" http://localhost/${install_name}/install.php

  cus_echo "第九步"
  curl -o install.html -b cookies.cook -d "current_step=9&goto=Next" http://localhost/${install_name}/install.php >&/dev/null 2>&1

  cus_echo "第十步"
  curl -o install.html -b cookies.cook -d "current_step=10&language=en_us&install_type=custom&default_user_name=admin&goto=Next" http://localhost/${install_name}/install.php >&/dev/null 2>&1
  sleep 3

  cus_echo "第十.二步"
  curl -o install.html http://localhost/${install_name}/index.php

  after_install
}

init_db()
{
  type expect>&/dev/null 2>&1
  [[ ! $? == 0  ]] && echo "系统需要安装expect支持，使用 : sudo apt-get install expect expect-dev 进行安装" && echo "" && exit 1
  cus_echo "初始化数据库 : ${db_name} "
  expect ${SCRIPT_DIR}/initdb.exp ${DB_USER} ${DB_PWD} ${db_name} ${INITDB_PATH}
}

data_loader()
{
  cus_echo "data loader"
  [[ "XGIT" == "X${install_meth}" ]] &&
    {
      cd ${GIT_DIR}/ibm/dataloaders
    cat <<CONFIG > config.php
<?php

\$config = array(

        // DB settings 
        'db' => array(
                'type' => 'db2', // mysql or db2
                'host' => '127.0.0.1',
                'port' => '${DB_PORT}',
                'username' => '${DB_USER}',
                'password' => '${DB_PWD}',
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
CONFIG

      php populate_SmallDataset.php && git checkout ${GIT_DIR}/ibm/dataloaders/config.php

      cd ${WEB_DIR}/${install_name}/custom/cli
      php -f cli.php task=RebuildClientHierarchy && php -f cli.php task=UpdateUsersTopTierNode

      cd ${WEB_DIR}/${install_name}/batch_sugar/RTC_19211
      php -f rtc_19211_main.php RTC_19211>&/dev/null 2>&1

      cp -r ${GIT_DIR}/sugarcrm/tests ${WEB_DIR}/${install_name}
      chmod 755 ${WEB_DIR}/${install_name}/tests/phpunit.php ${WEB_DIR}/${install_name}/tests/phpunit2.php

    } || 
    {
      echo 'url'
    }
}

add_ignore()
{
  cat <<IGNORE > .gitignore
.gitignore
*.sql
*.log
.*
cache
IGNORE
}

add_project()
{
  cat <<PROJECT > .project
<?xml version="1.0" encoding="UTF-8"?>
<projectDescription>
	<name>${install_name}</name>
	<comment></comment>
	<projects>
	</projects>
	<buildSpec>
		<buildCommand>
			<name>org.eclipse.wst.common.project.facet.core.builder</name>
			<arguments>
			</arguments>
		</buildCommand>
	</buildSpec>
	<natures>
		<nature>org.eclipse.wst.common.project.facet.core.nature</nature>
	</natures>
</projectDescription>
PROJECT
}

after_install()
{
  # data loader
  time data_loader

  cd ${WEB_DIR}/${install_name}

  cus_echo "设置git ignore"
  add_ignore

  cus_echo "添加Zend Studio项目文件"
  add_project

  cus_echo "初始化GIT库"
  git init
  {
    git add . && git commit -m 'init'
  }>&/dev/null

  cd ${SCRIPT_DIR}

  # 删除安装文件信息
  rm -rf *.html cookies.cook
  
  cus_echo "安装完成"
  google-chrome http://localhost/${install_name}/index.php
}

# 入口文件
for i in $@; do
  [[ "X${i}" == 'X--debug' ]] && set -x && shift && break
done

while [ "$1" != '' ]; do
  case $1 in
    -h | --help )
      echo "help"
      exit 0
      ;;
    --mas-remote )
      shift && mas_remote=$1 && shift
      ;;
    --fet-remote )
      shift && fet_remote=$1 && shift
      ;;
    --debug )
      set -x && shift
      ;;
    -d )
      shift && db_name=${1} && shift
      ;;
    -g | --git )
      install_meth="GIT"
      shift
      mas_branch=${1:?"必须指定fetch主分支"} && shift
      fet_branch=${1:?"必须指定合并分支，0为不合并任何分支"}
      shift
      get_db_name
      gen_install_name git ${mas_branch} ${fet_branch}
      echo ${install_name}
      ;;
    -u | --url )
      install_meth="URL"
      shift
      get_db_name
      # gen_install_name
      
      ;;
    * )
      shift
      ;;
esac
done

[[ -z ${install_meth} ]] && bash ${SCRIPT_DIR}/install.sh --help

# 准备安装
[[ "X${install_meth}" == "XGIT" ]] && time pre_git || time pre_url

# 开始安装
time install

