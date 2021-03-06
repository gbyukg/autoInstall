#!/usr/bin/env bash

sysname=$(uname)

readonly WEB_DIR="/document/gbyukg/www/sugar"
readonly GIT_DIR="/document/gbyukg/www/Mango"
readonly BUILD_DIR="/document/gbyukg/www/sugar/build_path"
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly INITDB_PATH="./"
readonly SITE_USER="admin"
readonly SITE_PWD="admin"
. "${HOME}/.ssh/key"

[[ "X${sysname}" == "XDarwin" ]] &&
    readonly DB_USER="gbyukg" ||
    readonly DB_USER="db2inst1"

readonly DB_PWD="admin"
readonly DB_HOST="localhost"
readonly DB_PORT="50000"

site_url="http://localhost/"
#ver="6.4.0"
ver="7.1.5"
db_name=""
mas_remote="upstream"
fet_remote="origin"
mas_branch=""
fet_branch=""
install_meth=""
install_name=""
download_url="http://sc2.gnuhub.com/sugarsync/"
#man_url=""
down_file=""
import_avl="0"
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
    echo "$(tput setaf 5)${star}${1}${star}$(tput sgr0)"
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

get_pull()
{
    local install_dir="${WEB_DIR}/${2}"
    local patch_name="${1}.patch"
    cd "${SCRIPT_DIR}"
    source "${HOME}/.ssh/token"
    if [ ! -d "${install_dir}" ]; then
        cus_echo "文件夹：${install_dir} 不存在"
        exit 1
    fi

    curl -o "diff.patch" https://api.github.com/repos/sugareps/Mango/pulls/"${1}" \
        -H "Accept: application/vnd.github.v3.patch" \
        -H "Authorization: token ${token}"

    sed -e 's/\([a,b]\)\/sugarcrm/\1/g' diff.patch > "${patch_name}"
    rm "diff.patch"
    mv -f "${1}.patch" "${install_dir}"
    cd "${install_dir}"

    git apply --check "${patch_name}"
    if [ "0" != "$?" ]; then
        cus_echo "无法应用补丁文件：${patch_name}"
        exit 1;
    fi
    cus_echo "将要被应用的补丁文件内容"
    git apply --stat "${patch_name}"
    git apply "${patch_name}"
    exit 0;
}

create_pull_request()
{
    local title=${1}
    local head=${2}
    local base=${3}
    local body=${4}

    cus_echo "\"${title}\" : ${2} -> ${3} \"${4}\""

    cd "${SCRIPT_DIR}"
    source "${HOME}/.ssh/token"

    curl https://api.github.com/repos/sugareps/Mango/pulls \
        -d '{"title":"'"${title}"'", "head":"'"gbyukg:${head}"'","base":"'"${base}"'","body":"'"${body}"'"}' \
        -H "Authorization: token ${token}" \
        -H "Content-Type: application/json"
}

pre_git()
{
    echo ""
    echo "选择的是GIT安装方式"
    echo ""
    cd "${GIT_DIR}"

    install_branch_name="install_${install_name}"

    {
        git show-branch "${install_branch_name}">/dev/null &&
        {
            git checkout ibm_r20 && cus_echo "删除已有分支 : ${install_branch_name}" && git branch -D "${install_branch_name}"
        } 2>>"${SCRIPT_DIR}"/install.log && err_hand "错了！！！！！！！！！！"
    }

    # begain
    cus_echo "fetch遠程分支代碼: ${mas_remote}" && git fetch "${mas_remote}" &&
    cus_echo "创建新分支 : ${install_name}(基于远程分支${mas_remote}/${mas_branch})" &&
    git checkout -b "install_${install_name}" ${mas_remote}/${mas_branch} &&
    if [[ "${ver}" == "7.1.5" ]]; then
    cus_echo "submodule update" &&
        git submodule update --recursive && {
        [[ -z ${fet_branch} || "X0" == "X${fet_branch}" ]] ||
            {
                cus_echo "合并远程分支分支:${fet_remote}" && git pull -v --no-edit --stat --summary ${fet_remote} ${fet_branch}
                #cus_echo "合併遠程分支 分支:${fet_remote}" && git merge --no-commit --no-edit --progress --stat -v ${fet_remote}/${fet_branch}
            }
        }
    fi
    # end
    err_hand "创建分支失败"

    cus_echo "构建代码 -> ${BUILD_DIR}"
    {
        cus_echo " 删除构建文件${BUILD_DIR} " && rm -rf "${BUILD_DIR}"/*
        cus_echo " 删除原文件${install_name} " && rm -rf "${WEB_DIR}"/"${install_name}"
    }>/dev/null 2>&1
    cd "${GIT_DIR}"/build/rome
    rm -rf "${BUILD_DIR}"/*
    php build.php -clean -cleanCache -flav=ult -ver="${ver}" -dir=sugarcrm -build_dir="${BUILD_DIR}" &&
    cp -R "${BUILD_DIR}"/ult/sugarcrm "${WEB_DIR}"/"${install_name}"
    #cp -R "${SCRIPT_DIR}/sugar/autoloader.php" "${WEB_DIR}"/"${install_name}/include/utils/"
    #cp -R "${SCRIPT_DIR}/sugar/Elastica" "${WEB_DIR}"/"${install_name}/vendor/"
}

load_avl()
{
    cus_echo 开始导入AVL
    cd "${WEB_DIR}"/"${install_name}"/custom/cli
    cus_echo "avl.csv"
    php cli.php task=Avlimport file="${WEB_DIR}"/"${install_name}"/custom/install/avl.csv idlMode=true
    cus_echo "01-update.csv"
    php cli.php task=Avlimport file="${WEB_DIR}"/"${install_name}"/custom/install/avl/01-update.csv
    cus_echo "02-remap.csv"
    php cli.php task=Avlimport file="${WEB_DIR}"/"${install_name}"/custom/install/avl/02-remap.csv
    cus_echo "03-update.csv"
    php cli.php task=Avlimport file="${WEB_DIR}"/"${install_name}"/custom/install/avl/03-update.csv
    cus_echo "04-update.csv"
    php cli.php task=Avlimport file="${WEB_DIR}"/"${install_name}"/custom/install/avl/04-update.csv
    cus_echo "05-update.csv"
    php cli.php task=Avlimport file="${WEB_DIR}"/"${install_name}"/custom/install/avl/05-update.csv
    cus_echo "06-winplan.csv"
    php cli.php task=Avlimport file="${WEB_DIR}"/"${install_name}"/custom/install/avl/06-winplan.csv
}

pre_url()
{
    cus_echo "选择的是URL安装方式"
    cus_echo "开始下载文件:${down_file}"
    [ -d sugarcrm ] && rm -rf sugarcrm
    wget -O sugarcrm.zip "${download_url}" || exit 1
    cus_echo "开始解压"
    unzip -d sugarcrm sugarcrm.zip &> /dev/null || exit 1
    [ -d "${WEB_DIR}"/"${install_name}" ] && cus_echo "删除原有文件${WEB_DIR}/${install_name}" && rm -rf "${WEB_DIR}"/"${install_name}"
    local sugar_dir_name=$(ls -d sugarcrm/SugarUlt-Full-*)
    echo ${install_name}
    mv "${sugar_dir_name}" "${WEB_DIR}/${install_name}"
    rm -rf sugarcrm.zip
}

install()
{
    site_url=${site_url}${install_name}

    # 初始化数据库
    time init_db

    cus_echo "开始安装"
    cd "${SCRIPT_DIR}"

    cus_echo "安装初始化"
    curl -o install.html -D cookies.cook "${site_url}"/install.php >/dev/null 2>&1
    sleep 3

    curl -o install.html -b cookies.cook -d "\
language=en_us\
&current_step=0\
instance_url="${sit_url}"/install.php\
&goto=Next" \
    "${site_url}"/install.php >&/dev/null 2>&1
    sleep 3

    cus_echo "第一步"
    curl -o install.html -b cookies.cook -d "\
current_step=1\
&goto=Next" \
    "${site_url}"/install.php >&/dev/null 2>&1
    sleep 3

    cus_echo "check system"
    curl -o install.html -b cookies.cook -d "\
checkInstallSystem=true\
&to_pdf=1\
&sugar_body_only=1" \
    "${site_url}"/install.php >&/dev/null 2>&1
    sleep 3

    cus_echo "第二步"
    curl -o install.html -b cookies.cook -d "\
setup_license_accept=on\
&current_step=2\
&goto=Next" \
    "${site_url}"/install.php >&/dev/null 2>&1
    sleep 3

    cus_echo "第三步"
    curl -o install.html -b cookies.cook -d "\
setup_license_key=${KEY}\
&install_type=custom\
&current_step=3\
&goto=Next" \
    "${site_url}"/install.php >&/dev/null 2>&1
    sleep 3

    cus_echo "第四步"
    curl -o install.html -b cookies.cook -d "\
setup_db_type=ibm_db2\
&current_step=4\
&goto=Next" \
    "${site_url}"/install.php >&/dev/null 2>&1
    sleep 3

    cus_echo "check db"
    curl -o install.html -b cookies.cook -d "\
checkDBSettings=true\
&to_pdf=1\
&sugar_body_only=1\
&setup_db_database_name=${db_name}\
&setup_db_port_num=${DB_PORT}\
&setup_db_host_name=${DB_HOST}\
&setup_db_admin_user_name=${DB_USER}\
&setup_db_admin_password=${DB_PWD}\
&fts_type=Elastic\
&fts_host=localhost\
&fts_port=9200\
&demoData=no" \
    "${site_url}"/install.php >&/dev/null 2>&1
    sleep 3

    cus_echo "第五步"
    curl -o install.html -b cookies.cook -d "\
setup_db_drop_tables=\
&goto=Next\
&setup_db_database_name=${db_name}\
&setup_db_host_name=${DB_HOST}\
&setup_db_port_num=${DB_PORT}\
&setup_db_create_sugarsales_user=\
&setup_db_admin_user_name=${DB_USER}\
&setup_db_admin_password_entry=${DB_PWD}\
&setup_db_admin_password=${DB_PWD}\
&demoData=no\
&fts_type=Elastic\
&fts_host=localhost\
&fts_port=9200\
&current_step=5" \
    "${site_url}"/install.php >&/dev/null 2>&1
    sleep 3

    cus_echo "第六步"
    curl -o install.html -b cookies.cook -d "\
current_step=6\
&goto=Next\
&goto=Next&setup_site_url=${site_url}\
&setup_system_name=SugarCRM\
&setup_site_admin_user_name=${SITE_USER}\
&setup_site_admin_password=${SITE_PWD}\
&setup_site_admin_password_retype=${SITE_PWD}" \
    "${site_url}"/install.php >&/dev/null 2>&1
    sleep 3

    cus_echo "第七步"
    curl -o install.html -b cookies.cook -d "\
current_step=7\
&goto=Next\
&setup_site_sugarbeet_anonymous_stats=yes\
&setup_site_sugarbeet_automatic_checks=yes\
&setup_site_session_path=\
&setup_site_log_dir=\
&setup_site_guid=" \
    "${site_url}"/install.php >&/dev/null 2>&1

    cus_echo "第八步"
    curl -o install.html -b cookies.cook -d "current_step=8&goto=Next" "${site_url}"/install.php

    cus_echo "第九步"
    curl -o install.html -b cookies.cook -d "current_step=9&goto=Next" "${site_url}"/install.php >&/dev/null 2>&1

    cus_echo "第十步"
    curl -o install.html -b cookies.cook -d "\
current_step=10\
&language=en_us\
&install_type=custom&default_user_name=admin\
&goto=Next" \
    "${site_url}"/install.php >&/dev/null 2>&1
    sleep 3

    cus_echo "第十.二步"
    curl -o install.html "${site_url}"/index.php

    after_install
}

init_db()
{
    if [[ "X${sysname}" == "XDarwin" ]];then
        cus_echo "初始化数据库 : ${db_name} "
        bash $HOME/init4sugar.sh ${db_name}
    else
        type expect>&/dev/null 2>&1
        [[ ! $? == 0  ]] && echo "系统需要安装expect支持，使用 : sudo apt-get install expect expect-dev 进行安装" && echo "" && exit 1
        cus_echo "初始化数据库 : ${db_name} "
        expect "${SCRIPT_DIR}"/initdb.exp "${DB_USER}" "${DB_PWD}" "${db_name}" "${INITDB_PATH}"
    fi
}

data_config()
{
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
        'directory' => '${WEB_DIR}/${install_name}',
    ),

);
CONFIG
}

add_ignore()
{
    cat <<IGNORE > .gitignore
.gitignore
*.sql
*.log
.*
notes
cache
create_tag.sh
repair.sh
tags
sidecar/minified
*.patch
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
        <name>org.eclipse.wst.validation.validationbuilder</name>
        <arguments>
        </arguments>
    </buildCommand>
    <buildCommand>
        <name>org.eclipse.dltk.core.scriptbuilder</name>
        <arguments>
        </arguments>
    </buildCommand>
</buildSpec>
<natures>
    <nature>org.eclipse.php.core.PHPNature</nature>
</natures>
</projectDescription>
PROJECT
}

data_loader()
{
    cus_echo "data loader"

    if [[ "XGIT" == "X${install_meth}" ]]; then
        cd "${GIT_DIR}"/ibm/dataloaders
        cp -r "${GIT_DIR}"/sugarcrm/tests "${WEB_DIR}"/"${install_name}"
        #chmod 755 "${WEB_DIR}"/"${install_name}"/tests/phpunit.php "${WEB_DIR}"/"${install_name}"/tests/phpunit2.php
    else
        cd "${SCRIPT_DIR}"/sugarcrm/ibm/dataloaders
    fi

    data_config
    php populate_SmallDataset.php
    [ X"GIT" == X"${install_meth}" ] && cd "${GIT_DIR}" && git checkout ibm/dataloaders/config.php

    cd "${WEB_DIR}"/"${install_name}"/batch_sugar/RTC_19211
    php -f rtc_19211_main.php RTC_19211>&/dev/null 2>&1
}

create_tag()
{
    cat << CREATETAG > create_tag.sh
exec ctags -f tags \\
-h ".php" -R \\
--exclude="\.git" \\
--exclude="cache" \\
--exclude="include/javascript" \\
--exclude="tests" \\
--exclude="custom/include/javascript" \\
--exclude="sidecar" \\
--exclude="styleguide" \\
--totals=yes \\
--tag-relative=yes \\
--PHP-kinds=+cf \\
--regex-PHP='/abstract class ([^ ]*)/\1/c/' \\
--regex-PHP='/interface ([^ ]*)/\1/c/' \\
--regex-PHP='/(public |static |abstract |protected |private )+function ([^ (]*)/\2/f/'
CREATETAG

    chmod 755 create_tag.sh
    ./create_tag.sh
}

restApi_config()
{
    cat <<CONFIG> config.php
<?php

\$config = array(

    // SugarCRM settings
    'sugar_user' => '${SITE_USER}',
    'sugar_password' => '${SITE_PWD}',
    'sugar_encryption' => '', // set to PLAIN or 3DES for LDAP auth
    'sugar_encryption_key' => '', // LDAP encryption key for 3DES
    'sugar_url' => '${site_url}',
    'sugar_api' => 'v4_ibm',
    
    // String to identify this application
    'sugar_api_app' => 'API Testing',
    
    // Specify the API mode: soap, wsdl or rest
    'api_mode' => 'soap',
    
    // WSDL specific
    'wsdl_use_cache' => false,
    
    // DB settings (
    'db_type' => 'db2', // mysql or db2
    'db_host' => '${DB_HOST}',
    'db_port' => '${DB_PORT}',
    'db_username' => '${DB_USER}',
    'db_password' => '${DB_PWD}',
    'db_name' => '${db_name}',
    
    // Zend Studio debug settings
    'zend_debug' => false,
    'zend_debug_host' => 'celeborn.sugar',
    'zend_debug_port' => '10137',
    
    // XDebug settings
    'xdebug' => true,
    'xdebug_idekey' => 'ECLIPSE_DBGP',
    
    // runtime config overrides
    'php_ini' => array(
        'default_socket_timeout' => 1200,
    ),
);
CONFIG
}

after_install()
{
    # data loader
    time data_loader

    # fix db
    #expect "${SCRIPT_DIR}"/createDB.exp "${DB_USER}" "${DB_PWD}" "${db_name}" "${INITDB_PATH}"

    # setup rest api
    # php run.php -j IbmRevenueLineItems_15119aTest
    rm -rf "${WEB_DIR}/${install_name}/ibm/api2"
    cp -r "${GIT_DIR}/ibm/api2" "${WEB_DIR}/${install_name}/ibm/"
    cd "${WEB_DIR}/${install_name}/ibm/api2"
    restApi_config

    # 导入avl
    [ "X1" == "X${import_avl}" ] && time load_avl

    # 创建CGTT_SEED_ID表
    #cus_echo "创建缺省数据库"
    #expect "${SCRIPT_DIR}"/creatDB.exp "${DB_USER}" "${DB_PWD}" "${db_name}" "${INITDB_PATH}"

    cd "${WEB_DIR}/${install_name}"
    #echo "\$sugar_config['connections_base_url'] ='https://devconnections2.rtp.raleigh.ibm.com';
        #\$sugar_config['connections_http_base_url'] = 'https://devconnections2.rtp.raleigh.ibm.com';
        #\$sugar_config['ieb_connections_base_url'] = 'http://ebs01.raleigh.ibm.com:3470';
        #\$sugar_config['functional_id'] = 'helenbyrne10@tst.ibm.com';
        #\$sugar_config['connections_common_path'] = '/common';
        #\$sugar_config['enable_collab'] = true;" >> config_override.php

    touch sql.sql
    touch notes

    cp -r "${SCRIPT_DIR}"/xhprof_lib ./
    cp "${SCRIPT_DIR}"/ChromePhp.php include/ChromePhp.php
    echo "require_once 'ChromePhp.php';" >> include/utils.php

    cus_echo "设置git ignore"
    add_ignore

    cus_echo "添加Zend Studio项目文件"
    add_project

    type ctags > /dev/null 2>&1
    [ 0 == $? ] && {
    cus_echo "生成tags"
    create_tag
    }
    cp "${SCRIPT_DIR}"/repair.sh "${WEB_DIR}"/"${install_name}"/repair.sh

    #cus_echo "导入products产品线"
    #db2 connect to ${db_name}
    #db2 'delete from ibm_products'
    #echo "db2 'import from ${SCRIPT_DIR}/prod.csv of del insert_update into ibm_products'"

    cus_echo "初始化GIT库"
    git init
    {
        git add . && git commit -m 'init'
    }>&/dev/null

    cd "${SCRIPT_DIR}"

    # 删除安装文件信息
    rm -rf \*.html cookies.cook

    cus_echo "安装完成"
    if [[ "X${sysname}" == "XDarwin" ]];then
        open /Applications/Google\ Chrome.app http://127.0.0.1/"${install_name}/index.php"
    else
        (type google-chrome > /dev/null 2>&1 && google-chrome http://localhost/"${install_name}"/index.php) || 
        {
            (type chromium-browser > /dev/null 2>&1 && chromium-browser google-chrome http://localhost/"${install_name}"/index.php) || 
            {
                firefox http://localhost/"${install_name}"/index.php
            }
        }
    fi
}

install_check()
{
    pgrep httpd > /dev/null 2>&1
    [ 0 != $? ] && echo "Apache 未起動" && exit 1

    ES=$(ps aux | ack-grep elasticsearch | wc -l)
    #echo $es
    (("${ES}" < 2)) && echo "ES未起动" && exit 1
}
# 入口文件
install_check
for i in "$@"; do
    [[ "X${i}" == 'X--debug' ]] && set -x && shift && break
done

while [ "$1" != '' ]; do
    case $1 in
        -h | --help )
            echo "help"
            echo '-g/--git git check主分支 自己分支'
            echo '-u/--url url 包名'
            echo '-d dbName git:默认gitsugar; url默认urlsugar'
            echo '--mas-remote upstream'
            echo '--fet-remote origin'
            echo '--debug'
            echo '-v 7 用于安装7.0版本'
            echo '-r 补丁号 sugarcrm的安装路径'
            echo '-p ibmd_XXX ibm_r20 title command 创建pull request'
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
            gen_install_name git "${mas_branch}" "${fet_branch}"
            ;;
        -u | --url )
            install_meth="URL"
            shift
            get_db_name
            down_file="${1}"
            if test -n "${1}"; then
                download_url="${download_url}/${1}"
                shift
            else
                cus_echo "请输入下载地址"
                exit 1
            fi
            down_file=${down_file%\.*}
            down_file=${down_file##*/}
            gen_install_name url "${down_file}" 0
            ;;
        -r )
            install_meth="refresh"
            shift
            pull_no=${1:?"必须指定pull request号"} && shift
            sugar_dir=${1:?"必须指定sugarcrm安装目录"}
            shift
            get_pull "${pull_no}" "${sugar_dir}"
            ;;
        -v | --ver )
            shift
            ver=${1:?"使用该选项必须指定build版本号 默认6.4.0"}
            [ "$1" == "7" ] && ver="7.1.5"
            shift
            ;;
        --avl )
            shift
            import_avl="1";
            ;;
        -p )
            head=${2:?請輸入被合併的分支號}
            base=${3:?請輸入要合併進的分支號}
            title=${4:?請輸入標題}
            body=${5:?請輸入command}
            create_pull_request "${title}" "${head}" "${base}" "${body}"
            exit
            ;;
        * )
            shift
            ;;
    esac
done

[[ -z "${install_meth}" ]] && bash "${SCRIPT_DIR}"/install.sh --help && exit 1

case "${install_meth}" in
    "GIT" )
        time pre_git
        ;;
    "URL" )
        time pre_url
        ;;
    "refresh" )
        ;;
    * )
        exit 0
esac

time install

