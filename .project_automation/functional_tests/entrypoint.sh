#!/bin/bash -e

## NOTE: paths may differ when running in a managed task. To ensure behavior is consistent between
# managed and local tasks always use these variables for the project and project type path
PROJECT_PATH=${BASE_PATH}/project
PROJECT_TYPE_PATH=${BASE_PATH}/projecttype

echo "Starting Funtional Tests"

cd ${PROJECT_PATH}

#********** Get TF-Vars ******************
aws ssm get-parameter \
    --name "/terraform-aws-ec2-image-builder-windows" \
    --with-decryption \
    --query "Parameter.Value" \
    --output "text" \
    --region "us-east-1">>tf.auto.tfvars
#********** Checkov Analysis *************
echo "Running Checkov Analysis"
terraform init
terraform plan -out tf.plan
terraform show -json tf.plan  > tf.json 
checkov 


#********** Terratest execution **********
echo "Running Terratest"
cd test/windows
rm -f go.mod
go mod init github.com/aws-ia/terraform-project-ephemeral
go mod tidy
go install github.com/gruntwork-io/terratest/modules/terraform
go test -timeout 160m

#********** Get TF-Vars ******************
aws ssm get-parameter \
    --name "/terraform-aws-ec2-image-builder-linux" \
    --with-decryption \
    --query "Parameter.Value" \
    --output "text" \
    --region "us-east-1">>tf.auto.tfvars
#********** Checkov Analysis *************
echo "Running Checkov Analysis"
terraform init
terraform plan -out tf.plan
terraform show -json tf.plan  > tf.json 
checkov 

#********** Terratest execution **********
echo "Running Terratest"
cd test/linux
rm -f go.mod
go mod init github.com/aws-ia/terraform-project-ephemeral
go mod tidy
go install github.com/gruntwork-io/terratest/modules/terraform
go test -timeout 160m

echo "End of Functional Tests"