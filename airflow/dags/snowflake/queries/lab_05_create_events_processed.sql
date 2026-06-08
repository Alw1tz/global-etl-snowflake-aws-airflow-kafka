CREATE OR REPLACE TABLE {sink} (
    id           NUMBER,
    event_type   VARCHAR(50),
    payload      VARIANT,
    processed_at TIMESTAMP
)
