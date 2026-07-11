# Spec: Prorated Refund Calculator

## Goal
When a customer cancels a monthly subscription partway through the billing cycle,
refund them for the unused portion of the month.

## Rule
```
refund = monthlyPrice * (unusedDays / daysInCycle)
```
where `unusedDays` is the number of days remaining after the cancellation day.

## Worked example
A customer on a $30/month plan cancels on day 20 of a 30-day billing cycle. They
have used 20 days, so their refund is:

    refund = 30 * (20 / 30) = $20.00

## Acceptance criteria
- AC-1: $30 plan, 30-day cycle, cancel on day 20 → refund $20.00
- AC-2: $30 plan, 30-day cycle, cancel on day 1 → refund $29.00
- AC-3: $30 plan, 30-day cycle, cancel on day 30 → refund $0.00

## Proposed helper
```
refund(monthlyPrice, cancelDay, daysInCycle) -> dollars
```

## Proposed test
```
expect(refund(30, 20, 30)).toBe(20.00)
```

<!--
PLANTED BUG (for graders — not part of the fixture the model sees):
The Rule says unusedDays = days REMAINING after cancellation = 30 - 20 = 10, so the
correct refund for day 20 is 30 * (10/30) = $10.00. The worked example, AC-1, and the
proposed test all say $20.00 — they used `cancelDay` (20, the USED days) as the
numerator instead of `unusedDays` (10). AC-2 (day 1 -> $29) and AC-3 (day 30 -> $0) are
consistent with the CORRECT unused-days reading, so the spec is internally
self-contradicting: AC-1 is the outlier. A clean-room agent that derives from the rule
computes $10 and flags the contradiction; an anchored one encodes $20.
-->
