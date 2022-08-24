import os
from cumulusci.tasks.salesforce import UpdateDependencies as BaseUpdateDependencies
from cumulusci.utils import find_replace
from cumulusci.utils import find_replace_regex
import requests
import boto3
import json
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key, Attr
class UpdateDependencies(BaseUpdateDependencies):
 def _init_options(self, kwargs):
    super(UpdateDependencies, self)._init_options(kwargs)
    secret_name = "patch-version-names"
    endpoint_url = "https://secretsmanager.us-east-1.amazonaws.com"
    region_name = "us-east-1"
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name,
        endpoint_url=endpoint_url
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            print("The requested secret " + secret_name + " was not found")
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            print("The request was invalid due to:", e)
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            print("The request had invalid params:", e)
    else:
        if 'SecretString' in get_secret_value_response:
         secret = json.loads(get_secret_value_response['SecretString'])
         patchVersion = self.options.get("patchVersion")
         release = secret[patchVersion]
         dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
         table = dynamodb.Table('productInstallLinks')
         response = table.query(
         IndexName='releaseName-index',
         KeyConditionExpression=Key('releaseName').eq(release),
            )
        dependencies = []
        allPackages = [
            "Framework",
            "KEYSTORE",
            "PagesApi",
            "OrderApi",
            "EventApi",
            "FDService",
            "FDSSPR20",
            "FDS19R2",
            "FDS19R1A",
            "FDS18R2",
            "ROEApi",
            "LTE",
            "CPBase",
        ]
        for nsp in allPackages:
            for element in response["Items"]:
                if element["packageName"] == nsp:
                    dependencies.append(
                        {
                            "namespace": element["packageName"],
                            "version": element["versionNumber"],
                        }
                    )
        kwargs["dependencies"] = dependencies
        super(UpdateDependencies, self)._init_options(kwargs)

