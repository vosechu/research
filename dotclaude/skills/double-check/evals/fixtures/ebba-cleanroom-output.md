Clean-room test suite returned for the Error Budget Burn Alert (EBBA) feature:

1. Given 10 errors out of 1000 transactions, the computed error rate is 0.01; with
   threshold 0.05, no alert is raised.
2. Given 200 errors out of 1000 transactions, the computed error rate is 0.20; with
   threshold 0.05, an alert is raised.
3. Given 40 errors out of 200 transactions, the computed error rate is 0.20; with
   threshold 0.05, an alert is raised.
4. Given an error rate exactly equal to the threshold (0.05), no alert is raised,
   because the rule is strictly greater-than.
5. While an alert is already open for a service, a second qualifying poll does not
   raise a duplicate alert.
6. The service caches each NRDB response in a Redis key `ebba:{service}` with a
   5-minute TTL, and a second poll within 5 minutes reads from the cache.
7. When total transactions is 0 and errors is 0, the computed error rate is 0.0 and
   no alert is raised.
8. The dashboard renders the current error rate as a gauge widget that turns red when
   an alert is open and green otherwise.
9. The errorRate() helper returns a value of type float.
