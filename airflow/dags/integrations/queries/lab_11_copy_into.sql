COPY INTO {table}
FROM 's3://{bucket}/{key}'
CREDENTIALS = (
    AWS_KEY_ID     = '{aws_key_id}'
    AWS_SECRET_KEY = '{aws_secret_key}'
)
FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1)
ON_ERROR   = CONTINUE
