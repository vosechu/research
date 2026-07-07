# Spec: Error Budget Burn Alert (EBBA)

## Goal
A small service that periodically queries NRDB for a service's error rate over a
window and raises an alert when the error rate exceeds a configured threshold.

## Behavior
- Poll every 5 minutes.
- Compute error rate = (count of error transactions) / (count of all transactions)
  over the last 1 hour.
- If error rate > threshold (default 0.05 = 5%), raise an alert; otherwise stay quiet.
- Idempotent: do not re-raise while an alert for the same service is already open.

## NRQL (proposed)
The service computes the rate with this query:

    SELECT count(*) WHERE error IS true / count(*) AS errorRate
    FROM Transaction WHERE appName = {service} SINCE 1 hour ago

## errorRate() helper (proposed signature)
    errorRate(errorCount, totalCount) -> float   // returns errorCount / totalCount

## Acceptance criteria
- AC-1: threshold 0.05, given 1000 transactions and 10 errors, errorRate = 0.01 and NO alert fires.
- AC-2: threshold 0.05, given 1000 transactions and 200 errors, errorRate = 0.20 and an alert fires.
- AC-3: threshold 0.05, given 200 transactions and 40 errors, errorRate = 0.02 and NO alert fires.
- AC-4: while an alert is already open for a service, a second qualifying poll does not raise a duplicate alert.

## Example test (proposed)
    expect(errorRate(40, 200)).toBe(0.02)
