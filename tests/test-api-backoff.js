// SPDX-License-Identifier: 0BSD
// Simulate actual service request handlers and verify retry scheduling.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const policy = vm.createContext({});
vm.runInContext(fs.readFileSync('package/contents/ui/RefreshPolicy.js', 'utf8'), policy);
const minute = 60000;
const now = 1770000000000;
for (const [status, times] of [[429,[10,20,30,30]], [500,[4,8,16,30]], [503,[4,8,16,30]]]) {
    times.forEach((n,i) => assert.equal(policy.httpRetryIntervalMs(status,i+1),n*minute));
}
for (const status of [0,400,404,600])
    assert.equal(policy.httpRetryIntervalMs(status,10),2*minute);
assert.equal(policy.httpRetryIntervalMs(429,NaN),10*minute);
assert.equal(policy.httpRetryIntervalMs(503,1000),30*minute);
assert.equal(policy.shouldRefresh(now,0,now-9*minute,false,true,10*minute),false);
assert.equal(policy.shouldRefresh(now,0,now-10*minute,false,true,10*minute),true);
assert.equal(policy.shouldRefresh(now,0,now-2*minute,false,true,0),true);
assert.equal(policy.shouldRefresh(now,0,now-8*60*minute,false,true,30*minute),true);
assert.equal(policy.shouldRefresh(now,now-30*minute,now-30*minute,false,false,30*minute),true);
assert.equal(policy.shouldRefresh(now,0,now-30*minute,true,true,30*minute),false);

const main=fs.readFileSync('package/contents/ui/main.qml','utf8');
const source=fs.readFileSync('package/contents/ui/WeatherService.qml','utf8');
assert.match(main,/weatherService\.error\.length > 0,\s*weatherService\.retryIntervalMs\)\)/);
assert.match(main,/onClicked: root\.refreshWeather\(\)/);
assert.match(main,/interval: 60000; repeat: true; running: root\.validLocation; onTriggered: root\.refreshIfDue\(\)/);
const functions=['reportFailure','setRetryForStatus','cancelDueToTimeout','refresh'].map(name=>{
    const found=source.match(new RegExp('^    function '+name+'\\([^\\n]*?\\) \\{[\\s\\S]*?^    \\}','m'));
    assert.ok(found,name);
    return found[0];
}).join('\n');
function makeTest() {
    const requests=[];
    let time=now;
    class XHR {
        static DONE=4;
        constructor(){this.readyState=0;this.status=0;requests.push(this);}
        open(method,url){this.url=url;}
        send(){this.sent=true;}
        abort(){this.aborted=true;this.status=0;this.readyState=4;
            if(this.onreadystatechange)this.onreadystatechange();
            if(this.onerror)this.onerror();}
        respond(status,body=''){this.status=status;this.responseText=body;
            this.readyState=4;if(this.onreadystatechange)this.onreadystatechange();}
        fail(){this.status=0;this.readyState=4;if(this.onerror)this.onerror();}
    }
    const s={busy:false,hasData:false,error:'',data:{},lastLocationKey:'',
        lastRequestedLocationKey:'',lastAttemptMs:0,lastSuccessMs:0,
        generation:0,currentRequest:null,serverFailureCount:0,
        retryIntervalMs:2*minute,requestStarted(){},
        lastWarnedError:'',lastWarnedAtMs:0};
    const logs=[];
    const scope={XMLHttpRequest:XHR,RefreshPolicy:policy,
        Weather:{makeForecast:()=>({ok:true})},Date:{now:()=>time},
        encodeURIComponent,isFinite,Math,console:{warn:x=>logs.push(x)}};
    for(const key of Object.keys(s))
        Object.defineProperty(scope,key,{get:()=>s[key],set:value=>{s[key]=value;}});
    const ctx=vm.createContext(scope);
    vm.runInContext(functions,ctx);
    return {requests,s,logs,refresh:(lat=40)=>ctx.refresh(lat,-73,'fahrenheit','mph'),
        timeout:()=>ctx.cancelDueToTimeout(),advance:ms=>{time+=ms;}};
}
{
    const x=makeTest();
    x.refresh();x.requests[0].respond(429);
    assert.equal(x.s.retryIntervalMs,10*minute);
    assert.equal(x.s.serverFailureCount,1);
    x.refresh();x.requests[1].respond(429);
    assert.equal(x.s.retryIntervalMs,20*minute);
    // An intentional manual refresh is still immediate.
    x.refresh();x.requests[2].respond(503);
    assert.equal(x.s.retryIntervalMs,16*minute);
    x.refresh();x.requests[3].fail();
    assert.equal(x.s.retryIntervalMs,2*minute);
    assert.equal(x.s.serverFailureCount,0);
    x.refresh();x.requests[4].respond(500);
    assert.equal(x.s.retryIntervalMs,4*minute);
    x.refresh();x.requests[5].respond(200,'{}');
    assert.equal(x.s.hasData,true);
    assert.equal(x.s.serverFailureCount,0);
    assert.equal(x.s.retryIntervalMs,2*minute);
    x.refresh();x.requests[6].respond(429);
    assert.equal(x.s.hasData,true);
    x.refresh(41);
    assert.equal(x.s.hasData,false);
    assert.equal(x.s.retryIntervalMs,2*minute);
    x.requests[7].respond(503);
    x.refresh();x.timeout();
    assert.equal(x.s.serverFailureCount,0);
    assert.equal(x.s.retryIntervalMs,2*minute);
    assert.equal(x.s.busy,false);
}
{
    const x=makeTest();
    x.refresh();x.requests[0].respond(400);
    assert.equal(x.requests.length,2);
    assert.doesNotMatch(x.requests[1].url,/moonrise/);
    x.requests[1].respond(200,'{}');
    assert.equal(x.s.hasData,true);
    assert.equal(x.s.retryIntervalMs,2*minute);
}
// A request may issue both DONE(0) and onerror; only the first callback
// should report an error. Suppress identical warnings during long outages,
// but preserve user-facing status and report changes, success or new towns.
{
    const x=makeTest();
    x.refresh(); x.requests[0].respond(0); x.requests[0].fail();
    assert.equal(x.logs.length,1);
    assert.match(x.s.error,/No HTTP response/);
    x.refresh(); x.requests[1].respond(0);
    assert.equal(x.logs.length,1);
    x.advance(30*minute);
    x.refresh(); x.requests[2].respond(0);
    assert.equal(x.logs.length,2);
    x.refresh(); x.requests[3].respond(503);
    assert.equal(x.logs.length,3);
    x.refresh(); x.requests[4].respond(200,'{}');
    x.refresh(); x.requests[5].respond(503);
    assert.equal(x.logs.length,4);
    x.refresh(41); x.requests[6].respond(503);
    assert.equal(x.logs.length,5);
    x.refresh(); const old=x.requests[7]; x.refresh(); old.fail();
    assert.equal(x.logs.length,5);
    assert.equal(x.s.busy,true);
    x.requests[8].respond(200,'{}');
}
{
    const x=makeTest();
    x.refresh(); x.requests[0].respond(400); x.requests[0].fail();
    assert.equal(x.logs.length,0);
    x.requests[1].respond(200,'{}');
    assert.equal(x.s.error,'');
}
console.log('Provider retries, network recovery, timeout and scoped diagnostics passed');
