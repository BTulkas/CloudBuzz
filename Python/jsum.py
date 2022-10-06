from email.message import Message
import json
import boto3


def lambda_handler(event, context):

    sns_client = boto3.client('sns')

    sns_client.publish(
        TopicArn = 'arn:aws:sns:eu-central-1:626438822359:send_email_topic',
        Message = str(int(event['num1']) + int(event['num2']))
        )

    # return {
    #     'response': (int(event['num1']) + int(event['num2']))
    # }