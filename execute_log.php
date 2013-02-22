<?php
if(isset($_POST['sub']) && $_POST['sub'] != null)
{
	// 	exec_shell();
	// 	sleep(2);
	ob_end_flush();
	$file_handle = fopen("output", "r");
	$line = null;
	$size = 0;
	while (!stristr($line, 'success!!!')) {
		fseek($file_handle, $size);
		$line = fgets($file_handle);
		$len = strlen($line);
		echo $line . '<br/>';
		flush();
		$size += strlen($line);
		sleep(1);
	}
	fclose($file_handle);
}
