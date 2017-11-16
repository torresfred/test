# PeopleSoft Deployment Repo

Code related to deploying, bootstrapping new client 

## Process Overview

1. *SCI Task* - Request AWS Account
2. *SCI Task/Customer Task* - Determine CIDR Range
3. *Customer Task* - Determine Region
4. *SCI Task* - Execute Cloudformation Stacks
    1. VPC
    2. ...
5. *SCI Task* - Setup Jumphost
6. *SCI Task* - Execute DPKs for building AMIs