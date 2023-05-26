import os
import boto3
import json


def lambda_handler(event, context):
    # TODO implement

    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table("books")
    value_list = table.scan()

    if event["httpMethod"] == "GET":
        return get_request(value_list)
    elif event["httpMethod"] == "POST":
        return post_request(table, event)
    elif event["httpMethod"] == "DELETE":
        return delete_request(table)


def get_request(table):
    # Handle GET request
    return


def post_request(table, event):
    # Handle POST request
    payload = json.loads(event["body"])

    if "bookid" not in payload:
        return {"statusCode": 400, "body": "Missing 'bookid' attribute in the payload"}

    item = payload

    table.put_item(Item=item)

    return {"statusCode": 200, "body": "POST request processed"}


def put_request(table, event):
    # Handle PUT request
    return


def delete_request(table, event):
    # Handle DELETE request
    return
