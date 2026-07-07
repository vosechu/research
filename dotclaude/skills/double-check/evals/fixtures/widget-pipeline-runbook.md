# Widget Pipeline — Operations Runbook

The Widget Pipeline ingests vendor parts files and emits normalized Widget records.

## Key facts
- Batch cadence: the pipeline runs every **15 minutes** (not continuously).
- Max batch size: **5,000** parts files per run. Larger uploads are split.
- Retry policy: failed batches retry **3 times** with exponential backoff (base 30s).
- Dead-letter: after retries exhaust, the batch lands in the `wp-dlq` SQS queue.
- Ownership: the Parts Platform team owns the pipeline; on-call rotation is `pp-oncall`.
- Region: runs in us-west-2 only. There is no EU deployment as of this writing.
