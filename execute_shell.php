<?php
$output = shell_exec('./test.sh ' . $_POST['install_method'] . ' ' . $_POST['dbname'] . ' ' . $_POST['host'] . ' '. $_POST['port'] . ' ' . $_POST['username'] . ' '. $_POST['pwd'] . ' ' . $_POST['param_7'] . ' ' . $_POST['param_8'] . ' > output');
//$output = shell_exec("./test.sh > output");
?> 
