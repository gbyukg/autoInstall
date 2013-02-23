#!/usr/bin/env php

<?php
#error_reporting(0);
$filename = $argv[1];
$dbname = $argv[2];
$params ['post_fields'] = array (
		'第一步' => array (
				'language' => 'en_us',
				'current_step' => 0,
				'goto' => 'Next'
		),
		'第二步' => array (
				'current_step' => 1,
				'goto' => 'Next'
		),

		'第二.2步' => array (
				'checkInstallSystem' => true,
				'to_pdf' => 1,
				'sugar_body_only' => 1
		),
		'第三步' => array (
				'setup_license_accept' => 'on',
				'current_step' => '2',
				'goto' => 'Next'
		),
		'第四步' => array (
				'setup_license_key' => 'internal sugar user 20100224',
				'install_type' => 'custom',
				'current_step' => 3,
				'goto' => 'Next'
		),
		'第五步' => array (
				'setup_db_type' => 'ibm_db2',
				'current_step' => 4,
				'goto' => 'Next'
		),
		'check database' => array (
				'checkDBSettings' => true,
				'to_pdf' => 1,
				'sugar_body_only' => 1,
				'setup_db_database_name' => $dbname,
				'setup_db_port_num' => '',
				'setup_db_host_name' => 'localhost',
				'setup_db_admin_user_name' => 'db2inst1',
				'setup_db_admin_password' => 'admin',
				'demoData' => 'no'
		),
		'第六步' => array (
				'checkDBSettings' => true,
				'setup_db_drop_tables' => false,
				'goto' => 'Next',
				'setup_db_database_name' => $dbname,
				'setup_db_host_name' => 'localhost',
				'setup_db_prot_num' => null,
				'setup_db_create_sugarsales_user' => '',
				'setup_db_admin_user_name' => 'db2inst1',
				'setup_db_admin_password_entry' => 'admin',
				'setup_db_admin_password' => 'admin',
				'demoData' => 'no',
				'current_step' => 5
		),
		'第七步' => array (
				'current_step' => 6,
				'setup_site_url' => 'http://www.sugar.com/SugarUlt-Full-6.4.0',
				'setup_system_name' => 'SugarCRM',
				'setup_site_admin_user_name' => 'admin',
				'setup_site_admin_password' => 'admin',
				'setup_site_admin_password_retype' => 'admin',
				'goto' => 'Next'
		),
		'第八步' => array (
				'current_step' => 7,
				'setup_site_sugarbeet_anonymous_stats' => 'yes',
				'setup_site_session_path' => '',
				'setup_site_log_dir' => '.',
				'setup_site_guid' => '',
				'goto' => 'Next'
		),
		'第九步' => array (
				'current_step' => 8,
				'goto' => 'Next'
				),
		'第十步' => array(
				'current_step' => 9,
				'goto' => 'Next'
				),
		'第十一步' => array(
				'current_step' => '10',
				'language' => 'en_us',
				'install_type' => 'custom',
				'default_user_name' => 'admin',
				'goto' => 'Next'
				),
);

$url = 'http://www.sugar.com/' . $filename . '/install.php';
$ch  = curl_init($url);
//创建一个用于存放cookie信息的临时文件
$cookie = tempnam('.','~');
curl_setopt ( $ch, CURLOPT_HEADER, false );
curl_setopt ( $ch, CURLOPT_NOBODY, true );
curl_setopt ( $ch, CURLOPT_RETURNTRANSFER, true );
curl_setopt ( $ch, CURLOPT_COOKIESESSION, true );
curl_setopt ( $ch, CURLOPT_POST, true );

foreach ($params['post_fields'] as $key1=>$val)
{
	curl_setopt($ch, CURLOPT_COOKIEJAR, $cookie);
	curl_setopt($ch, CURLOPT_COOKIEFILE, $cookie);
	
	curl_setopt($ch, CURLOPT_POST, count($val));
	$fields_string = '';
	foreach($val as $key => $value)
	{
		$fields_string .= $key . '=' . $value . '&';
	}
	curl_setopt($ch, CURLOPT_POSTFIELDS, $fields_string);
// 	echo '<h1>' . $key1 .'</h1><br\>';
	echo "\n" . $key1 .'...';
	$response= curl_exec($ch);
	//echo $response;
}
curl_close($ch);
echo "安装完毕\n访问地址：http://www.sugar.com/$filename/index.php\n";
