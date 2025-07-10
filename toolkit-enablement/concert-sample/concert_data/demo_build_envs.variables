
##########################################################################
# Copyright IBM Corp. 2024.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
##########################################################################

##
# Container command and options used on this environment
##
export OPTIONS="-it --rm -u $(id -u):$(id -g)"
export CONTAINER_COMMAND="podman run"

##
# Templates
##
export TEMPLATE_PATH=../templates

##
# Common Variables
##
export CONCERT_TOOLKIT_IMAGE="icr.io/cpopen/ibm-concert-toolkit:latest"
export CONCERT_TOOLKIT_UTILS_REPO="https://github.com/IBM/Concert.git"
export CONCERT_URL="https://150.240.66.145:12443/"
export INSTANCE_ID="0000-0000-0000-0000"
# TODO: Fill in the API KEY
export API_KEY="Your API Key"
export SPEC_VERSION="1.0.4"

##
# Application Variables
##
# TODO: Make sure the App name is the same as what you define in Instana
export APP_NAME="Your application name"
export APP_VERSION="1.0.0.0"

export ENVIRONMENT_NAME_1="development"
export ENVIRONMENT_NAME_2="pre-production"
export ENVIRONMENT_NAME_3="production"

export COMPONENT_NAME="robot-shop-web"
export COMPONENT_VERSION="1.0.0"

export BUSINESS_NAME="MyOrg"
export BUSINESS_UNIT_NAME="Business Unit name"
export CONTACT_EMAIL="myemail@myorg.com"
export CONTACT_PHONE="(123) 123-1234"

export APPLICATION_CRITICALITY=5
export END_POINT_NAME="web-frontend"
export ACCESS_POINT_NAME=${END_POINT_NAME}
export COMPONENT_ENDPOINTS="/login"
export NETWORK_EXPOSURE="public"

##
# Emulate a Build Inventory SBOM
##
export COMPONENT_SOURCECODE_REPO_NAME="robot-shop-web"
export COMPONENT_SOURCECODE_REPO_URL="https://github.com/ibm-apac-itca/robot-shop"
export COMPONENT_IMAGE_NAME="robotshop/rs-web"
export COMPONENT_IMAGE_TAG="latest"
export COMPONENT_BUILD_NUMBER=1

##
# Emulate a Deployment Inventory SBOM
##
export DEPLOYMENT_REPO_NAME="myapp-component"
export DEPLOYMENT_REPO_URL="https://github.com/myorg/myapp-component"
export DEPLOYMENT_REPO_BRANCH="main"
export ENVIRONMENT_TARGET="production"
export CHANGE_REQUEST_URL="https://github.com/myorg/myapp-component/issues/1"

export APP_URL="https://internal.myorg.com/myappservice"

export RUNTIME_1_NAME="techzone-minikube"
export K8_PLATFORM="minikube"
export CLUSTER_PLATFORM="ibm"
# TODO: Fill in Cluster_ID (same as CLUSTER_NAME) as in Instana
export CLUSTER_ID="techzone-minikube"
export CLUSTER_REGION="us-east-1"
export CLUSTER_NAME=${CLUSTER_ID}
export CLUSTER_API_SERVER="https://mycluster.us-east-1.containers.cloud.ibm.com:12345"
export CLUSTER_NAMESPACE="robot-shop"

# export RUNTIME_2_NAME="rhel-vm-1"
# export VM_OS_NAME="RHEL"
# export VM_OS_VERSION="8.4"
# export VM_HOSTNAME="myrhelvm1.mycompany.io"
# export VM_IPV4="101.136.92.110"
# export VM_IPV6="0d87:96f4:78ec:401b:d83d:5f35:d5fe:19bb"
# export VM_IMAGE="localhost/isolated-component"
# export VM_IMAGE_TAG="latest"

# export RUNTIME_3_NAME="mydb"
# export DB_TYPE="mysql"
# export DB_VERSION="8.0"
# export DB_NAME="mydb"
# export DB_HOST="mydb.mycompany.io"
# export DB_PORT=330

##
# simulate_ci_pipeline.sh generated vars below
##
