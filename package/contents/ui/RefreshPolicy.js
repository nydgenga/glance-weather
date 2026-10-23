// SPDX-License-Identifier: 0BSD
// Wall-clock refresh decisions, independent of Qt's animation-based Timer.
// Normal updates are half-hourly; network errors retry every two minutes.
// API rate-limit and server failures back off without creating new timers.
var NORMAL_INTERVAL_MS = 30 * 60 * 1000;
var RETRY_INTERVAL_MS = 2 * 60 * 1000;
var STALLED_REQUEST_MS = 25 * 1000;
var MAX_HTTP_RETRY_MS = 30 * 60 * 1000;

// Avoid hammering Open-Meteo after a 429 or 5xx response. Other errors retain
// the fast 2-minute retry used for suspend/network reconnection recovery.
function httpRetryIntervalMs(status, consecutiveFailures) {
    if (status !== 429 && (status < 500 || status >= 600))
        return RETRY_INTERVAL_MS;
    var count = isFinite(consecutiveFailures) ? Math.max(1, Math.floor(consecutiveFailures)) : 1;
    var base = status === 429 ? 10 * 60 * 1000 : 4 * 60 * 1000;
    return Math.min(MAX_HTTP_RETRY_MS, base * Math.pow(2, Math.min(count - 1, 4)));
}


function shouldRefresh(nowMs, lastSuccessMs, lastAttemptMs, busy, hasError, retryIntervalMs) {
    if (!isFinite(nowMs) || busy) return false;
    if (!lastAttemptMs) return true; // first run
    // Clock corrections and resume should never leave scheduling stuck.
    if (lastAttemptMs > nowMs || lastSuccessMs > nowMs) return true;
    if (hasError || !lastSuccessMs) {
        var delay = isFinite(retryIntervalMs) && retryIntervalMs >= RETRY_INTERVAL_MS
            ? Math.min(retryIntervalMs, MAX_HTTP_RETRY_MS) : RETRY_INTERVAL_MS;
        return nowMs - lastAttemptMs >= delay;
    }
    return nowMs - lastSuccessMs >= NORMAL_INTERVAL_MS;
}

function requestIsStalled(nowMs, lastAttemptMs, busy) {
    if (!busy || !isFinite(nowMs) || !lastAttemptMs) return false;
    return nowMs < lastAttemptMs || nowMs - lastAttemptMs >= STALLED_REQUEST_MS;
}
