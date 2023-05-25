import os
import boto3
import json


def lambda_handler(event, context):
    # TODO implement

    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table("books")
    value_list = table.scan()

    return {
        "statusCode": 200,
        "body": json.dumps({"statusCode": 200, "data": value_list}),
    }
