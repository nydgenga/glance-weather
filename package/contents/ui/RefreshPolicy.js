// SPDX-License-Identifier: 0BSD
// Wall-clock refresh decisions, independent of Qt's animation-based Timer.
// Normal updates are half-hourly; failed requests retry every two minutes.
var NORMAL_INTERVAL_MS = 30 * 60 * 1000;
var RETRY_INTERVAL_MS = 2 * 60 * 1000;
var STALLED_REQUEST_MS = 25 * 1000;

function shouldRefresh(nowMs, lastSuccessMs, lastAttemptMs, busy, hasError) {
    if (!isFinite(nowMs) || busy) return false;
    if (!lastAttemptMs) return true; // first run
    // Clock corrections and resume should never leave scheduling stuck.
    if (lastAttemptMs > nowMs || lastSuccessMs > nowMs) return true;
    if (hasError || !lastSuccessMs)
        return nowMs - lastAttemptMs >= RETRY_INTERVAL_MS;
    return nowMs - lastSuccessMs >= NORMAL_INTERVAL_MS;
}

function requestIsStalled(nowMs, lastAttemptMs, busy) {
    if (!busy || !isFinite(nowMs) || !lastAttemptMs) return false;
    return nowMs < lastAttemptMs || nowMs - lastAttemptMs >= STALLED_REQUEST_MS;
}
