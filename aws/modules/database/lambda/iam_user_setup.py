import json
import logging
import os
import boto3
import psycopg

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secrets_client = boto3.client("secretsmanager")


def get_secret(secret_arn):
    response = secrets_client.get_secret_value(SecretId=secret_arn)
    return json.loads(response["SecretString"])


def handler(event, context):
    logger.info("Starting IAM user setup")

    secret_arn = os.environ["DB_SECRET_ARN"]
    db_host = os.environ["DB_HOST"]
    db_port = int(os.environ.get("DB_PORT", "5432"))
    db_name = os.environ["DB_NAME"]
    db_user = os.environ["DB_USER"]

    credentials = get_secret(secret_arn)
    master_user = credentials["username"]
    master_password = credentials["password"]

    conn = None
    try:
        conn = psycopg.connect(
            host=db_host,
            port=db_port,
            dbname="postgres",
            user=master_user,
            password=master_password,
            sslmode="require",
            connect_timeout=10,
        )
        conn.autocommit = True
        cursor = conn.cursor()

        cursor.execute(
            "SELECT 1 FROM pg_roles WHERE rolname = %s",
            (db_user,)
        )
        user_exists = cursor.fetchone() is not None

        if user_exists:
            logger.info(f"User {db_user} already exists")
            cursor.close()
            return {"statusCode": 200, "body": json.dumps({"status": "exists"})}

        cursor.execute(f'CREATE USER "{db_user}" WITH LOGIN')
        logger.info(f"Created user: {db_user}")

        cursor.execute(f'GRANT rds_iam TO "{db_user}"')
        logger.info(f"Granted rds_iam to: {db_user}")

        cursor.execute(
            "SELECT 1 FROM pg_database WHERE datname = %s",
            (db_name,)
        )
        db_exists = cursor.fetchone() is not None

        if not db_exists:
            cursor.execute(f'CREATE DATABASE "{db_name}"')
            logger.info(f"Created database: {db_name}")

        cursor.execute(f'ALTER DATABASE "{db_name}" OWNER TO "{db_user}"')
        logger.info(f"Set {db_user} as owner of {db_name}")

        cursor.close()
        return {"statusCode": 200, "body": json.dumps({"status": "created"})}

    except Exception as e:
        logger.error(f"Error: {str(e)}")
        raise

    finally:
        if conn:
            conn.close()
