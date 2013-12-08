/*********************************************************************************
 * By installing or using this file, you are confirming on behalf of the entity
 * subscribed to the SugarCRM Inc. product ("Company") that Company is bound by
 * the SugarCRM Inc. Master Subscription Agreement (“MSA”), which is viewable at:
 * http://www.sugarcrm.com/master-subscription-agreement
 *
 * If Company is not bound by the MSA, then by installing or using this file
 * you are agreeing unconditionally that Company will be bound by the MSA and
 * certifying that you have authority to bind Company accordingly.
 *
 * Copyright (C) 2004-2013 SugarCRM Inc.  All rights reserved.
 ********************************************************************************/

/**
 * Created by JetBrains PhpStorm.
 * User: dtam
 * Date: 2/16/12
 * Time: 11:05 AM
 * This file initiates a sinon fake server which overloads the xhttp method on the browser and returns json data
 * which corresponds to routes stored in SUGAR.restDemoData.
 */
var SUGAR = SUGAR || {};

SUGAR.demoRestServer = function() {
    var requestIdx;
    var requestObj;

    if(!sinon || !sinon.fakeServer) {
        console.log("you need sinon");
        return
    }
    console.log("starting sinon fakeserver");
    var fakeServer =sinon.fakeServer.create();

    if(!SUGAR.restDemoData && SUGAR.restDemoData.length > 0) {
        console.log("no routes found");
        return;
    }
    console.log("registering routes");
    for (requestIdx in  SUGAR.restDemoData) {
        requestObj = SUGAR.restDemoData[requestIdx];
        fakeServer.respondWith(requestObj.httpMethod, requestObj.route,
            [200, {  "Content-Type":"application/json"},
                JSON.stringify(requestObj.data)]);
    }

    return fakeServer;

};