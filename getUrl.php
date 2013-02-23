<?php
function get_url($url)
{
	$ch = curl_init($url);
	curl_setopt ( $ch, CURLOPT_HEADER, false );
	curl_setopt ( $ch, CURLOPT_NOBODY, false );
	curl_setopt ( $ch, CURLOPT_RETURNTRANSFER, true );
	curl_setopt ( $ch, CURLOPT_COOKIESESSION, true );
	$response= curl_exec($ch);
	curl_close($ch);
	preg_match_all('/<a(.*?)href="(.*?)"(.*?)>(.*?)<\/a>/i',$response,$m);
	return $m;
// 	return $response;
}
if(isset($_GET['url']) && $_GET['url'] != '')
{
	//return get_url($_GET['url']);
	$response = get_url($_GET['url']);
	foreach($response[4] as $key=>$val)
	{
		echo $val . '@';
	}
// 	var_dump($_GET['url']);
// 	var_dump($response[4]);
}
// $url = 'http://sugjnk01.rtp.raleigh.ibm.com/';