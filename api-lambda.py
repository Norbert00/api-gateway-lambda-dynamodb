import os
import boto3


def lambda_handler(event, context):
    # TODO implement

    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table("books")
    value_list = table.scan()

    return value_list
