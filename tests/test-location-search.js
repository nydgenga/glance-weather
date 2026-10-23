// SPDX-License-Identifier: 0BSD
// Exercise QML's search controller with simulated network activity, not just regex.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('package/contents/ui/configGeneral.qml', 'utf8');
const funcs = ['cancelSearch', 'finishSearch', 'searchCities'];
const controller = funcs.map(name => {
    const rx = new RegExp('^    function ' + name + '\\([^\\n]*?\\) \\{[\\s\\S]*?^    \\}', 'm');
    const match = source.match(rx);
    assert.ok(match, `Missing controller function: ${name}`);
    return match[0];
}).join('\n');
assert.match(source, /interval: 15000/);
assert.match(source, /onTriggered: page\.cancelSearch\(i18n\("Location search timed out\. Try again\."\)\)/);
assert.match(source, /Component\.onDestruction: page\.cancelSearch\(""\)/);
assert.match(source, /onAccepted: page\.searchCities\(\)/);
assert.doesNotMatch(source, /setInterval|setTimeout/);

function harness() {
    const requests = [];
    const behavior = { throwOpen: false, throwSend: false };
    const timer = {
        running: false, restarts: 0, stops: 0,
        restart() { this.running = true; this.restarts++; },
        stop() { this.running = false; this.stops++; }
    };
    class FakeRequest {
        static DONE = 4;
        constructor() { this.readyState = 0; this.status = 0; this.aborted = false; requests.push(this); }
        open(method, url) { this.method = method; this.url = url; if (behavior.throwOpen) throw Error('open failed'); }
        send() { this.sent = true; if (behavior.throwSend) throw Error('send failed'); }
        abort() {
            this.aborted = true;
            this.readyState = FakeRequest.DONE;
            this.status = 0;
            // Simulate both callbacks that may fire during abort().
            if (this.onreadystatechange) this.onreadystatechange();
            if (this.onerror) this.onerror();
        }
        respond(status, payload) {
            this.status = status;
            this.responseText = typeof payload === 'string' ? payload : JSON.stringify(payload);
            this.readyState = FakeRequest.DONE;
            if (this.onreadystatechange) this.onreadystatechange();
        }
        fail() {
            this.status = 0;
            this.readyState = FakeRequest.DONE;
            if (this.onerror) this.onerror();
        }
    }
    const page = { searchGeneration: 0, activeSearchRequest: null,
        searching: false, locations: [], searchError: '' };
    const searchField = { text: 'Seattle' };
    const i18n = (s, arg) => s.replace('%1', String(arg));
    const context = vm.createContext({ page, searchTimeout: timer, searchField,
        XMLHttpRequest: FakeRequest, i18n, Array, JSON, encodeURIComponent });
    // QML resolves unqualified root-item properties through its scope. Mimic
    // that behavior when evaluating its JavaScript functions under Node.
    for (const name of ['searchGeneration', 'activeSearchRequest', 'searching',
                        'locations', 'searchError']) {
        Object.defineProperty(context, name, {
            get: () => page[name], set: value => { page[name] = value; }
        });
    }
    vm.runInContext(controller, context);
    for (const name of funcs) page[name] = context[name];
    return {page, requests, timer, behavior, field: searchField,
        timeout() { assert.equal(timer.running, true); page.cancelSearch(i18n('Location search timed out. Try again.')); }};
}

// Success: a normal search should finish and leave the Search button usable.
{
    const h = harness();
    h.page.searchCities();
    assert.equal(h.requests.length, 1);
    assert.equal(h.page.searching, true);
    assert.equal(h.timer.running, true);
    assert.match(h.requests[0].url, /name=Seattle/);
    h.requests[0].respond(200, {results: [{name: 'Seattle', latitude: 47.61, longitude: -122.33}]});
    assert.equal(h.page.searching, false);
    assert.equal(h.timer.running, false);
    assert.equal(h.page.activeSearchRequest, null);
    assert.equal(h.page.locations.length, 1);
    assert.equal(h.page.searchError, '');
}
// A stalled request times out, is aborted, and old callbacks cannot alter state.
{
    const h = harness();
    h.page.searchCities();
    const old = h.requests[0];
    h.timeout();
    assert.equal(old.aborted, true);
    assert.equal(h.page.searching, false);
    assert.equal(h.page.activeSearchRequest, null);
    assert.match(h.page.searchError, /timed out/);
    old.respond(200, {results: [{name: 'stale'}]});
    assert.equal(h.page.locations.length, 0);
    assert.match(h.page.searchError, /timed out/);
    h.page.searchCities();
    h.requests[1].respond(200, {results: [{name: 'new'}]});
    assert.equal(h.page.locations[0].name, 'new');
    assert.equal(h.page.searchError, '');
}
// Enter while busy replaces the previous request and ignores its late response.
{
    const h = harness();
    h.page.searchCities();
    const first = h.requests[0];
    h.field.text = 'Portland';
    h.page.searchCities();
    assert.equal(first.aborted, true);
    assert.equal(h.page.searching, true);
    assert.match(h.requests[1].url, /name=Portland/);
    first.respond(200, {results: [{name: 'Seattle'}]});
    assert.equal(h.page.locations.length, 0);
    h.requests[1].respond(200, {results: [{name: 'Portland'}]});
    assert.equal(h.page.locations[0].name, 'Portland');
}
// Failures and invalid responses cannot leave the UI stuck busy.
for (const failure of ['network', 'http', 'malformed', 'empty']) {
    const h = harness();
    h.page.searchCities();
    const request = h.requests[0];
    if (failure === 'network') request.fail();
    if (failure === 'http') request.respond(503, '');
    if (failure === 'malformed') request.respond(200, '{not-json');
    if (failure === 'empty') request.respond(200, {results: []});
    assert.equal(h.page.searching, false, failure);
    assert.equal(h.timer.running, false, failure);
    assert.equal(h.page.activeSearchRequest, null, failure);
    assert.ok(h.page.searchError.length > 0, failure);
}
// Page destruction invalidates and aborts requests.
{
    const h = harness();
    h.page.searchCities();
    h.page.cancelSearch('');
    assert.equal(h.requests[0].aborted, true);
    assert.equal(h.page.searching, false);
}
// Synchronous open/send exceptions do not strand the indicator.
for (const failure of ['throwOpen', 'throwSend']) {
    const h = harness();
    h.behavior[failure] = true;
    h.page.searchCities();
    assert.equal(h.page.searching, false, failure);
    assert.equal(h.timer.running, false, failure);
    assert.equal(h.page.activeSearchRequest, null, failure);
    assert.match(h.page.searchError, /Could not connect/, failure);
}
assert.match(source, /try \{\s*request\.open\([\s\S]*?request\.send\(\);\s*\} catch \(err\) \{\s*if \(finishSearch\(token, request\)\)/);
console.log('Location-search completion, timeout, replacement and failures passed');
