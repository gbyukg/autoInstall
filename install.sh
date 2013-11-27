#!/usr/bin/env bash

[ ! -n ${5:-} ] && set -x
set -x
# set -e

readonly WEB_DIR="/document/gbyukg/www/sugar"
readonly GIT_DIR="/document/gbyukg/www/mango"
readonly BUILD_DIR="/document/gbyukg/www/sugar/build_path"
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly INITDB_PATH="./"
readonly DB_USER="db2inst1"
readonly DB_PWD="admin"

db_name=""
mas_remote="upstream"
fet_remote="origin"
mas_branch=""
fet_branch=""
install_meth=""
install_name=""
begain="0"
star="********************"

err_hand()
{
  [[ X"$?" == X"0" ]] || {
    echo "${1}, 查看日志文件" && exit 1
  }
}

gen_install_name()
{
  install_name="${1}-${2}-${3}"
  install_name=${install_name/%-/}
}

pre_git()
{
  echo ""
  echo "选择的是GIT安装方式"
  echo ""
  cd ${GIT_DIR}

  install_branch_name="install-${install_name}"

  {
    git show-branch ${install_branch_name}>/dev/null && 
    {
      git checkout ibm_current && echo "${star}删除已有分支 : ${install_branch_name}${star}" && git branch -D ${install_branch_name}
    } 2>>${SCRIPT_DIR}/install.log && err_hand "错了！！！！！！！！！！"
  }
  echo ""

  # git fetch upstream && git checkout -b "install-${install_name}" upstream/${mas_branch} && {
  echo "${star}fetch远程代码 : ${mas_remote}${star}" && git fetch ${mas_remote} && echo "" && echo "${star}创建新分支 : ${install_name}(基于远程分支${mas_remote}/${mas_branch})${star}" && git checkout -b "install-${install_name}" ${mas_remote}/${mas_branch} && echo "" && {
    [[ -z ${fet_branch} ]] || echo "${star}合并远程分支分支:${fet_remote}${star}" && git pull --no-edit --stat --summary ${fet_remote} ${fet_branch}
  }
  err_hand "创建分支失败"

  echo ""
  echo "${star}构建代码 -> ${BUILD_DIR}${star}"
  {
    rm -rf ${BUILD_DIR}/*
    rm -rf ${WEB_DIR}/${install_name}
  }>/dev/null 2>&1
  cd ${GIT_DIR}/build/rome
  php build.php -clean -cleanCache -flav=ult -ver=6.4.0 -dir=sugarcrm -build_dir=${BUILD_DIR} && cp -r ${BUILD_DIR}/ult/sugarcrm ${WEB_DIR}/${install_name}

  time init_db

  time install
}

pre_url()
{
  echo ""
  echo "选择的是URL安装方式"
  echo ""
  install_meth="url"
}

install()
{
  pwd
  echo ""
  echo "${star}开始安装${star}"
  cd ${SCRIPT_DIR}

  echo "${star}第一步${star}"
  curl http://localhost/${install_name}/install.php -o step.html -D sugarInstallCookies >/dev/null 2>&1
  #sleep 5
  # curl -o install1.html -b sugarInstallCookies -c sugarInstallCookies -X POST --data "language=en_us&current_step=0&goto=next" http://localhost/${install_name}/install.php
  curli -o 1.html -b sugarInstallCookies -c sugarInstallCookies -d "language=en_us&current_step=0&goto=Next" http://localhost/${install_name}/install.php
  #sleep 5

  echo "${star}第二步${star}"
  curl -o 2.html -b sugarInstallCookies -d "current_step=1&goto=Next" http://localhost/${install_name}/install.php
  #sleep 5
  # curl -o install2.html -b sugarcookies --data "current_step=1&goto=next" http://localhost/${install_name}/install.php

  echo "${star}第三步${star}"
  curli -o 3.html -b sugarInstallCookies -d "checkInstallSystem=true&to_pdf=1&sugar_body_only=1" http://localhost/${install_name}/install.php
  #sleep 5
  
  echo "${star}第四步${star}"
  curl -o 4.html -b sugarInstallCookies sugarInstallCookies  -d "setup_license_accept=on&current_step=2&goto=Next" http://localhost/${install_name}/install.php
  #sleep 5
  
  echo "${star}第五步${star}"
  curl -o 5.html -b sugarInstallCookies sugarInstallCookies  -d "setup_license_key='internal sugar user 20100224'&install_type=custom&current_step=3&goto=Next" http://localhost/${install_name}/install.php
  #sleep 5
  
  echo "${star}第六步${star}"
  curl -o 6.html -b sugarInstallCookies sugarInstallCookies  -d "setup_db_type=ibm_db2&current_step=4&goto=Next" http://localhost/${install_name}/install.php
  #sleep 5
  
  
  echo "${star}第七步${star}"
  curl -o 7.html -b sugarInstallCookies sugarInstallCookies  -d "setup_db_type=ibm_db2&current_step=4&goto=Next" http://localhost/${install_name}/install.php
  #sleep 5
  
  
  echo "${star}第八步${star}"
  curli -o 8.html -b sugarInstallCookies sugarInstallCookies  -d "checkDBSettings=true&to_pdf=1&sugar_body_only=1&setup_db_database_name=${db_name}&setup_db_port_num=${db_port}&setup_db_host_name=localhost&setup_db_admin_user_name=${DB_USER}&setup_db_admin_password=${DB_PWD}&demoData=no" http://localhost/${install_name}/install.php
  #sleep 5
  
  
  echo "${star}第九步${star}"
  curl -o 9.html -b sugarInstallCookies sugarInstallCookies  -d "checkDBSettings=true&setup_db_drop_tables=false&got=Next&setup_db_database_name=${db_name}&setup_db_port_num=${db_port}&setup_db_host_name=localhost&setup_db_admin_user_name=${DB_USER}&setup_db_admin_password=${DB_PWD}&demoData=no&setup_db_create_sugarsales_user=&setup_db_admin_password_entry=admin" http://localhost/${install_name}/install.php
  #sleep 5
  
  
  echo "${star}第十步${star}"
  curl -o 10.html -b sugarInstallCookies sugarInstallCookies  -d "current_step=6&goto=Next&setup_site_url='http://www.sugar.com/SugarUlt-Full-6.4.0'&setup_system_name=SugarCRM&setup_site_admin_user_name=admin&setup_site_admin_password=admin&setup_site_admin_password_retype=admin" http://localhost/${install_name}/install.php
  #sleep 5
  
  
  echo "${star}第十一步${star}"
  curl -o 11.html -b sugarInstallCookies sugarInstallCookies  -d "current_step=7&goto=Nextsetup_site_sugarbeet_anonymous_stats=yes&setup_site_session_path=&setup_site_log_dir=&setup_site_guid=" http://localhost/${install_name}/install.php
}
init_db()
{
  type expect>&/dev/null 2>&1
  [[ ! $? == 0  ]] && echo "系统需要安装expect支持，使用 : sudo apt-get install expect expect-dev 进行安装" && echo "" && exit 1
  echo ""
  echo "${star}初始化数据库 : ${db_name} ${star}"
  expect ${SCRIPT_DIR}/initdb.exp ${DB_USER} ${DB_PWD} ${db_name} ${INITDB_PATH}
}

# 入口文件
while getopts "guh" opt
do
  case ${opt} in
    g)
      begain="1"
      [[ -z ${install_meth:-} ]] || exit 0
      mas_branch=${2:?"必须指定fetch主分支"}
      fet_branch=${3:?"必须指定合并分支，0为不合并任何分支"}
      [[ "0${3}" == "00" ]] && fet_branch="" || fet_branch="${3}"
      # db_name=${4:-gitsugar}
      db_name=${4:-urlsugar}
      gen_install_name git ${mas_branch} ${fet_branch}
      # time pre_git

      # 开始安装
      time install
      ;;
    u)
      begain="1"
      [[ -z ${install_meth:-} ]] || exit 0
      mas_url=${2}
      fet_url=${3}
      db_name=${4:-urlsugar}
      gen_install_name url ${mas_url} ${fet_url}
      pre_url
      ;;
    h)
      echo ""
      echo "-h"
      echo "-g 主分支名 合并分支名 数据库名(可选)"
      echo "-u 主URL地址 下载包名 数据库名(可选)"
      echo ""
      exit 0
      ;;
    *)
      echo 'Wrong!'
      exit 1
      ;;
esac
done

[[ "x0" == x${begain} ]] && bash ${SCRIPT_DIR}/install.sh -h
