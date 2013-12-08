<?php

if(!defined('sugarEntry'))define('sugarEntry', true);
require_once('include/entryPoint.php');

if(class_exists('DBManagerFactory')) {

	$db = DBManagerFactory::getInstance();
	$db->disconnect();

	error_reporting(E_ALL & ~E_NOTICE);

	$db->query("DELETE FROM ibm_roadmaps");
	$db->query("DELETE FROM ibm_cadences");
	$db->query("DELETE FROM ibm_adjustments");

	
	// genert a temporary timeperiod_id instead of get from table cause of there're no record data in table timeperiods
	$current_time = time();
	$q_timeperiods = "select id,end_date_timestamp from timeperiods where parent_id is not null and start_date_timestamp<=$current_time and end_date_timestamp>=$current_time and deleted!='1' limit 0,1";
	$res_timeperiods = $db->query($q_timeperiods, true);
	$timeperiods = $db->fetchByAssoc($res_timeperiods);
	$timeperiod_id = $timeperiods["id"];

	$q_rli = "
	select 
		rli.*, o.opportuf4b1ties_ida as opportunity_id
	from 
		ibm_revenuelineitems as rli
	left join 
		opportunevenuelineitems_c as o
	on 
		rli.id = o.opportu503dtems_idb
	where 
		rli.deleted!='1' and o.deleted!='1'
	LIMIT 0,100";
	$res_rli = $db->query($q_rli, true);

	// insert demo data for forcast worksheet
	$counter = 0;
	$randStatus = array('NIR', 'STR', 'ATR', 'SOL', 'WON');
	$randProbability = array('0', '10', '25', '50', '75', '100');

	$rli = array();
	while($rli = $db->fetchByAssoc($res_rli)) {

		//$probability = $owner ? $rli["probability"] : mt_rand(30, 100);
		//$status = $owner ? $rli["roadmap_status"] : mt_rand(1, 5);
		$probability = GetRandom($randProbability);
		$status = GetRandom($randStatus);
		$amount = mt_rand(100, 5000);

        $query = "
	        insert into 
				ibm_roadmaps 
				(
				  id,
				  name,
				  date_entered,
				  date_modified,
				  modified_user_id,
				  created_by,
				  description,
				  deleted,
				  assigned_user_id,
				  rli_id,
				  opportunity_id,
				  forecast_date,
				  probability,
				  roadmap_status,
				  revenue_amount,
				  lio_own,
				  match_lio_forecast,
				  timeperiod_id,
				  revenue_type
				)
			values
				(
					'".create_guid()."',
					'forcast worksheet demo $counter',
					current date,
					current date,
					'1',
					'1',
					'forcast worksheet demo data for testing',
					'0',
					'1',
					'".$rli["id"]."',
					'".$rli["opportunity_id"]."',
					current date,
					'".$probability."',
					'".$status."',
					'".$amount."',
					'0',
					'0',
					'".$timeperiod_id."',
					'".$rli["revenue_type"]."'
				)";
		$db->query($query);

		$counter++;

		// insert demo data for adjustments
		if($counter%4<1)
		{
		    $query = "
		    	insert into
		    		ibm_adjustments
					(
						id,
						name,
						date_entered,
						date_modified,
						modified_user_id,
						created_by,
						description,
						deleted,
						assigned_user_id,
						forecast_date,
						timeperiod_id,
						revenue_type,
						type,
						account_id,
						roadmap_status,
						revenue_amount,
						level10,
						level15,
						level20,
						level30,
						level40,
						solution_id
					)
				values
					(
						'".create_guid()."',
						'adjustment demo',
						current date,
						current date,
						'1',
						'1',
						'adjustment demo data for testing',
						'0',
						'1',
						current date,
						'".$timeperiod_id."',
						'".$rli["revenue_type"]."',
						'TYPE A',
						'".create_guid()."',
						'".$status."',
						'".$amount."',
						'".$rli["level10"]."',
						'".$rli["level15"]."',
						'".$rli["level20"]."',
						'".$rli["level30"]."',
						'".$rli["level40"]."',
						'".$rli["solution_id"]."'
					)
		    	";

		    $db->query($query);
		}
		// end insert adjustments

		// get next quarter
		if($counter%20<1)
		{
			$q_timeperiods = "select id,end_date_timestamp from timeperiods where parent_id is not null and start_date_timestamp>'".$timeperiods["end_date_timestamp"]."' and deleted!='1' limit 0,1";
			$res_timeperiods = $db->query($q_timeperiods, true);
			$timeperiods = $db->fetchByAssoc($res_timeperiods);
			$timeperiod_id = $timeperiods["id"];
		}
    }

    // calculate data for forcast summary
    $q_fwksheet = "
	    select 
	    	created_by,
	    	revenue_type,
	    	timeperiod_id,
	    	roadmap_status,
	    	sum(revenue_amount) as amount
	    from 
	    	ibm_roadmaps 
	    group by 
	    	created_by,
	    	revenue_type,
	    	timeperiod_id,
	    	roadmap_status
	    ";

    $res_fwksheet = $db->query($q_fwksheet, true);

    $users = array();
	while($wk = $db->fetchByAssoc($res_fwksheet))
    {
    	$users[$wk["created_by"]][$wk["revenue_type"]][$wk["timeperiod_id"]][$wk["roadmap_status"]] += $wk["amount"];
    }

    // insert demo data for forcast summary
    foreach ($users as $created_by => $revenue_types) {
    	if (is_array($revenue_types)) {
	    	foreach ($revenue_types as $type => $periods) {
	    		if (is_array($periods)) {
			    	foreach ($periods as $timeperiod_id => $values) {

			    		$won = $values["won"]>0 ? $values["won"] : 0;
						$solid = $values["solid"]>0 ? $values["solid"] : 0;
						$atrisk = $values["atrisk"]>0 ? $values["atrisk"] : 0;
						$stretch = $values["stretch"]>0 ? $values["stretch"] : 0;
						$nir = $values["nir"]>0 ? $values["nir"] : 0;
			    		
			    		$query = "
							insert into 
							ibm_cadences
								(
									id,
									name,
									date_entered,
									date_modified,
									modified_user_id,
									created_by,
									description,
									deleted,
									assigned_user_id,
									revenue_type,
									timeperiod_id,
									won_amount,
									solid_amount,
									atrisk_amount,
									stretch_amount,
									ho_stretch_amount,
									nir_amount
								)
							values
								(
									'".create_guid()."',
									'forcast demo',
									current date,
									current date,
									'1',
									'".$created_by."',
									'forcast demo data for testing',
									'0',
									'1',
									'".$type."',
									'".$timeperiod_id."',
									'".$won."',
									'".$solid."',
									'".$atrisk."',
									'".$stretch."',
									'0',
									'".$nir."'
								)";
						$db->query($query, true);
			    	}
		    	}
		    }
		}
    }

echo "demo data generated.\n";
}

function GetRandom($array, $start=0, $end=0)
{
	if ($end == "") {
		$end = count($array)-1;
	}
	$key = mt_rand($start, $end);
	return $array["$key"];
}
?>