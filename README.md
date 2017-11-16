# sci-cam-bootstrap

Code related to bootstrapping new client deployments in AWS via CloudFormation

## Process Overview

1. *SCI Task* - Determine client code, [gitlab repo token](#howto-gitlab-repo-token) (treat as secret), and [external ID](#howto-generate-a-unique-externalid) (treat as secret) for client
2. *SCI Task* - Deliver the following templates to client operations staff for deployment in account:
  - [sci-cam-bootstrap.json](https://git.myscims.com/sci-cloud/sci-cam-bootstrap/blob/master/cft/sci-cam-bootstrap.json)
  - [sci-cam-bootstrap-role.json](https://git.myscims.com/sci-cloud/sci-cam-bootstrap/blob/master/cft/sci-cam-bootstrap-role.json)
3. *Customer Task* - Deploys first CloudFormation template (sci-cam-bootstrap) to build Ansible client master host, VPC, and bucket using the following parameters:
  - StackName: **SciCamBootstrap** (exact name required)
  - ClientCode (SCI provides to client)
  - AvZone1 (drop down for current region)
  - AvZone2 (drop down for current region, must differ from AvZone1)
4. *Customer Task* - Deploy role template (sci-cam-bootstrap-role) with the following parameters:
  - StackName: **SciCamBootstrapRole** (exact name required)
  - BootstrapStackName (defaults to SciCamBootstrap, used for importing parameters from the first stack)
  - SciAccount (the SCI account from which S3 bootstrapping occurs)
  - SciExternalId (SCI provides to client, treat as secret, persist for duration of bootstrapping)
5. *Customer Task* - Notify SCI that both stacks have been created
6. *SCI Task* - Run Ansible playbook [camBootstrapFinalize.yaml](https://git.myscims.com/sci-cloud/sci-cam-bootstrap/blob/master/ansible/camBootstrapFinalize.yaml) to assume the SciCamBootstrapRole and do the following (note the trailing slash for the token_dir parameter):

    ```
    $ ansible-playbook ./camBootstrapFinalize.yaml --extra-vars "region=us-west-1 client_account=396492939101 external_id=ff86b4a9649865afee1c43e7786e9f85 token_dir=/Users/rcrelia/ token_file=gitlab-repo-token.ccd"
    ```
  - Where extra-vars has settings of:
      - region (Which S3 region to upload to,
      - client_account is a numeric-only string representing the customer's account number
      - token_dir is the location of the token_file on the local machine (where ansible-playbook is run from)
      - token_file is the file containing the GitLab token for use with the customer.
          - Filename must be formatted as gitab-repo-token.ZZZ, where ZZZ is the client code matching the GitLab repository (e.g., gitlab-repo-token.asu)
  - Uploads GitLab client-config repo token to client S3 bucket (file is stored encrypted via AES-256) created by CloudFormation stack **SciCamBootstrap**:
  - Within 60 seconds of the token copy, a process on the CAM will retrieve the repo token via S3 and configure the git repository pul
