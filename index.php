<?php
header("Content-type: text/html; charset=utf-8");

function exec_shell()
{
	$target  = '/autoInstall/execute_shell.php';
	foreach ($_POST as $key => $val)
	{
		$postValues .= urlencode( $key ) . "=" . urlencode( $val ) . '&';
	}
	$postValues = substr( $postValues, 0, -1 );
	$request  = "POST $target HTTP/1.1\r\n";
	$request .= "Host: 127.0.0.1\r\n";
	$lenght = strlen( $postValues );
	$request .= "Content-Type: application/x-www-form-urlencoded\r\n";
	$request .= "Content-Length: $lenght\r\n";
	$request .= "\r\n";
	$request .= $postValues;
	$socket  = fsockopen( 'localhost', 80, $errno, $errstr, 100000 );
	fputs( $socket, $request );
	fclose( $socket );
}

?>

<!Doctype html>
<html xmlns=http://www.w3.org/1999/xhtml>
<head>
<meta http-equiv=Content-Type content="text/html;charset=utf-8">
<meta http-equiv=X-UA-Compatible content=IE=EmulateIE7>
<title>SugarCRM</title>
<script type="text/javascript">
function install_opt(obj)
{
	if('url' == obj.value)
	{
		document.getElementById('git_install').style.display="none";
		document.getElementById('url_install').style.display="block";
	} else if('git' == obj.value)
	{
		document.getElementById('url_install').style.display="none";
		document.getElementById('git_install').style.display="block";
	}
}

function input_check(obj)
{
	if('url_sub' == obj.id)
	{
		if(document.getElementById('url_param_7').value == '')
		{
			alert('输入地址');
			return false;
		}
		if(document.getElementById('url_param_8').value == '')
		{
			alert('输入下载文件名');
			return false;
		}
	}
	else
	{
		if(document.getElementById('git_param_7').value == '')
		{
			alert('输入主分支名');
			return false;
		}
		
	}
}

function load_ajax(filename)
{
	var xmlhttp = null;
	try {
        xmlhttp = new XMLHttpRequest();
    } catch (e) {
        xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
    }
    
    xmlhttp.onreadystatechange = function() {
        if (4 == xmlhttp.readyState) {
            if (200 == xmlhttp.status) {
                var Bodys = xmlhttp.responseText;
                //document.getElementById('show_url').setAttribute("innerHTML", Bodys);
                return_value = Bodys.split('@');
                var len = return_value.length;
                var sugar_build = document.getElementById('url_param_8');
                sugar_build.options.length = 0;
                for(i=0; i<(len-1); i++)
                {
                	//var varItem = new Option(objItemText, objItemValue);      
                    sugar_build.options.add(new Option(return_value[i], return_value[i]));
                }
                //var varItem = new Option(objItemText, objItemValue);      
                //objSelect.options.add(varItem);

               // parent.document.all.iframemain.style.height = window.document.body.scrollHeight;
               // parent.document.all.iframemain.style.width = window.document.body.scrollWidth;
            }
        }
    }

//    xmlhttp.open("get", "getUrl.php?url=http://sugjnk01.rtp.raleigh.ibm.com/ibm_published_builds_r05_hotfix7/", true);
    xmlhttp.open("get", "getUrl.php?url=file:///document/gbyukg/www/sugar/autoInstall/" + filename, true);
    //xmlhttp.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
    xmlhttp.send("");
}
load_ajax();
</script>
</head>
<body>
	<h1>安装配置</h1>
	<label>请选择安装方式：</label>
	<select onchange="install_opt(this)">
		<option value="url"
			<?php if($_POST['install_method'] == 'url') echo 'selected="selected"';?>>url</option>
		<option value="git"
			<?php if($_POST['install_method'] == 'git') echo 'selected="selected"';?>>git</option>
	</select>
	<div style="border: solid 1px red; height: 250px">
		<div id="url_install" name="url_install"
			style="display: block; float: left">
			<form action="#" method="POST">
				<table>
					<tr>
						<td><label>地址:</label></td>
						<td><select id="url_param_7" name="url_param_7">
								<?php 
								foreach ($m[4] as $key => $val)
								{
									echo '<option value="' . $val . '">' . $val . '</option>';
								}
								?>
							</select></td>
					</tr>
					<tr>
						<td><label>下载文件名:</label></td>
<!-- 						<td><input id="url_param_8" name="param_8" size="30" /></td> -->
						<td>
							<select id="url_param_8" name="url_param_8">
								<option>选择下载文件</option>
							</select>
						</td>
					</tr>
					<tr>
						<td><label>数据库名:</label></td>
						<td><input id="dbname" name="dbname" size="30" value="sugarcrm" /></td>
					</tr>
					<tr>
						<td><label>数据库主机名:</label></td>
						<td><input id="host" name="host" size="30" value="localhost" /></td>
					</tr>
					<tr>
						<td><label>数据库端口号:</label></td>
						<td><input id="port" name="port" size="30" value="50000" /></td>
					</tr>
					<tr>
						<td><label>数据库用户名:</label></td>
						<td><input id="username" name="username" size="30"
							value="db2inst1" /></td>
					</tr>
					<tr>
						<td><label>数据库密码:</label></td>
						<td><input id="pwd" name="pwd" size="30" value="admin" /></td>
					</tr>
					<tr>
						<td><input type="submit" id="url_sub" name="sub" value="提交"
							onclick="return input_check(this);" /> <input type="hidden"
							id="install_method" name="install_method" value="url" /></td>
					</tr>
				</table>
			</form>
		</div>

		<div id="git_install" name="git_install"
			style="display: none; float: left">
			<form action="#" method="POST">
				<table>
					<tr>
						<td><label>主分支名:</label></td>
						<td><input id="git_param_7" name="param_7" size="30" /></td>
					</tr>
					<tr>
						<td><label>合并分支名:</label></td>
						<td><input id="git_param_8" name="param_8" size="30" /></td>
					</tr>
					<tr>
						<td><label>数据库名:</label></td>
						<td><input id="dbname" name="dbname" size="30" value="sugarcrm" /></td>
					</tr>
					<tr>
						<td><label>数据库主机名:</label></td>
						<td><input id="host" name="host" size="30" value="localhost" /></td>
					</tr>
					<tr>
						<td><label>数据库端口号:</label></td>
						<td><input id="port" name="port" size="30" value="50000" /></td>
					</tr>
					<tr>
						<td><label>数据库用户名:</label></td>
						<td><input id="username" name="username" size="30"
							value="db2inst1" /></td>
					</tr>
					<tr>
						<td><label>数据库密码:</label></td>
						<td><input id="pwd" name="pwd" size="30" value="admin" /></td>
					</tr>
					<tr>
						<td><input type="submit" id="git_sub" name="sub" value="提交"
							onclick="return input_check(this);" /> <input type="hidden"
							id="install_method" name="install_method" value="git" /></td>
					</tr>
				</table>
			</form>
		</div>
	</div>
	<div id="show_url"></div>
	<div style="border: solid 1px red; height:100px">
	<?php
	if(isset($_POST['sub']) && $_POST['sub'] != null)
	{
		exec_shell();
		sleep(2);
		ob_end_flush();
		
		$line = null;
		$size = 0;
		while (!stristr($line, 'success!!!')) {
			$file_handle = fopen("output", "r");
			fseek($file_handle, $size);
			$line = fgets($file_handle);
			$len = strlen($line);
			if($len ==0)
			{
				fclose($file_handle);
				continue;
			}
			echo $line . '<br/>';
			flush();
			$size += strlen($line);
			fclose($file_handle);
// 			sleep(1);
		}
	}
	?>
	</div>
</body>
</html>
