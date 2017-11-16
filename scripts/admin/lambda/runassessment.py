import boto3
import datetime

def lambda_handler(event, context):
    print("Run Assessment")

currentDT = datetime.datetime.now()
date = (currentDT.strftime("%Y-%m-%d-%H:%M:%S"))

client = boto3.client('inspector')

AR1 = "NPRD_linux-" + (currentDT.strftime("%Y-%m-%d-%H:%M"))
AR2 = "PRD_linux-" + (currentDT.strftime("%Y-%m-%d-%H:%M"))
AR3 = "NPRD_windows-" + (currentDT.strftime("%Y-%m-%d-%H:%M"))
AR4 = "PRD_windows-" + (currentDT.strftime("%Y-%m-%d-%H:%M"))


NPRD_linux = client.start_assessment_run(
    assessmentRunName=AR1,
    assessmentTemplateArn='arn:aws:inspector:us-east-1:674220205102:target/0-MTpceSCE/template/0-tCAmo05c'
)

PRD_linux = client.start_assessment_run(
    assessmentRunName=AR2,
    assessmentTemplateArn='arn:aws:inspector:us-east-1:674220205102:target/0-UFJpYkpq/template/0-m2zZmiJN'
)

NPRD_windows = client.start_assessment_run(
    assessmentRunName=AR1,
    assessmentTemplateArn='arn:aws:inspector:us-east-1:674220205102:target/0-2z93ny7n/template/0-RmnAlyfl'
)

PRD_windows = client.start_assessment_run(
    assessmentRunName=AR2,
    assessmentTemplateArn='arn:aws:inspector:us-east-1:674220205102:target/0-CuSBQzjB/template/0-8zLpVkfl'
)

print(NPRD_linux)
print(PRD_linux)
print(NPRD_windows)
print(PRD_windows)


you can delete this line