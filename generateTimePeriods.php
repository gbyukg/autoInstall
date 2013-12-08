<?php
if (!defined('sugarEntry')) define('sugarEntry', true);
require_once('include/entryPoint.php');

global $app_strings;
// the format of the quater timeperiod , like Q1 2013
$app_strings['LBL_QUARTER_TIMEPERIOD_FORMAT'] = 'Q{0} {1}';

// the settings of generating data
$settings = array(
    'timeperiod_start_date' => date("Y") . "-01-01", // which day start with
    'timeperiod_interval' => TimePeriod::ANNUAL_TYPE, //which type of the timeperiod
    'timeperiod_leaf_interval' => TimePeriod::QUARTER_TYPE, // which type of the leaf
    'timeperiod_shown_backward' => 1, // show how many years backward, 1 means cruuent year
    'timeperiod_shown_forward' => 20, // show how many years forward
);
/**
* generate time periods data
*/
class GenerateTimePeriodData
{
    public static function generateData($settings)
    {
        $timePeriod = TimePeriod::getByType(TimePeriod::ANNUAL_TYPE);
        $timePeriod->rebuildForecastingTimePeriods(array(), $settings);
    }
}

GenerateTimePeriodData::generateData($settings);