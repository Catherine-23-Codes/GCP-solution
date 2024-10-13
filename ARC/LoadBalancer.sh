#!/bin/bash

YELLOW='\033[0;33m'
NC='\033[0m'

pattern=(
"**********************************************************"
"**                 S U B S C R I B E  TO                **"
"**                 ABHI ARCADE SOLUTION                 **"
"**                                                      **"
"**********************************************************"
)

for line in "${pattern[@]}"
do
    echo -e "${YELLOW}${line}${NC}"
done
gcloud compute instances create utility-vm --project=$DEVSHELL_PROJECT_ID --zone=$FIRST_ZONE --machine-type=e2-medium --network-interface=private-network-ip=10.10.20.50,stack-type=IPV4_ONLY,subnet=subnet-a,no-address --metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --create-disk=auto-delete=yes,boot=yes,device-name=utility-vm,image=projects/debian-cloud/global/images/debian-11-bullseye-v20231010,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/us-central1-f/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any
gcloud compute networks subnets create my-proxy-subnet \
    --purpose=REGIONAL_MANAGED_PROXY \
    --role=ACTIVE \
    --region=$REGION_VALUE \
    --network=my-internal-app \
    --range=10.10.40.0/24
sleep 20
DEVSHELL_PROJECT_ID=$(gcloud config get-value project)
TOKEN=$(gcloud auth application-default print-access-token)
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "checkIntervalSec": 10,
    "description": "",
    "healthyThreshold": 2,
    "logConfig": {
      "enable": false
    },
    "name": "blue-health-check",
    "tcpHealthCheck": {
      "port": 80,
      "proxyHeader": "NONE"
    },
    "timeoutSec": 5,
    "type": "TCP",
    "unhealthyThreshold": 3
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/regions/$REGION_VALUE/healthChecks"
sleep 40
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "namedPorts": [
      {
        "name": "http",
        "port": 80
      }
    ]
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/zones/$FIRST_ZONE/instanceGroups/instance-group-1/setNamedPorts"
sleep 40
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"backends\": [
      {
        \"balancingMode\": \"UTILIZATION\",
        \"capacityScaler\": 1,
        \"group\": \"projects/$DEVSHELL_PROJECT_ID/zones/$FIRST_ZONE/instanceGroups/instance-group-1\",
        \"maxUtilization\": 0.8
      }
    ],
    \"connectionDraining\": {
      \"drainingTimeoutSec\": 300
    },
    \"description\": \"\",
    \"enableCDN\": false,
    \"healthChecks\": [
      \"projects/$DEVSHELL_PROJECT_ID/regions/$REGION_VALUE/healthChecks/blue-health-check\"
    ],
    \"loadBalancingScheme\": \"INTERNAL_MANAGED\",
    \"localityLbPolicy\": \"ROUND_ROBIN\",
    \"name\": \"blue-service\",
    \"portName\": \"http\",
    \"protocol\": \"HTTP\",
    \"region\": \"projects/$DEVSHELL_PROJECT_ID/regions/$REGION_VALUE\",
    \"sessionAffinity\": \"NONE\",
    \"timeoutSec\": 30
  }" \
  "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/regions/$REGION_VALUE/backendServices"
sleep 40 
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "checkIntervalSec": 10,
    "description": "",
    "healthyThreshold": 2,
    "logConfig": {
      "enable": false
    },
    "name": "green-health-check",
    "tcpHealthCheck": {
      "port": 80,
      "proxyHeader": "NONE"
    },
    "timeoutSec": 5,
    "type": "TCP",
    "unhealthyThreshold": 3
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/regions/$REGION_VALUE/healthChecks"
sleep 40
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "namedPorts": [
      {
        "name": "http",
        "port": 80
      }
    ]
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/zones/$SECOND_ZONE/instanceGroups/instance-group-2/setNamedPorts"
sleep 40
  curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{
      \"backends\": [
        {
          \"balancingMode\": \"UTILIZATION\",
          \"capacityScaler\": 1,
          \"group\": \"projects/$DEVSHELL_PROJECT_ID/zones/$SECOND_ZONE/instanceGroups/instance-group-2\",
          \"maxUtilization\": 0.8
        }
      ],
      \"connectionDraining\": {
        \"drainingTimeoutSec\": 300
      },
      \"description\": \"\",
      \"enableCDN\": false,
      \"healthChecks\": [
        \"projects/$DEVSHELL_PROJECT_ID/regions/$REGION_VALUE/healthChecks/green-health-check\"
      ],
      \"loadBalancingScheme\": \"INTERNAL_MANAGED\",
      \"localityLbPolicy\": \"ROUND_ROBIN\",
      \"name\": \"green-service\",
      \"portName\": \"http\",
      \"protocol\": \"HTTP\",
      \"region\": \"projects/$DEVSHELL_PROJECT_ID/regions/$REGION_VALUE\",
      \"sessionAffinity\": \"NONE\",
      \"timeoutSec\": 30
    }" \
    "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/regions/$REGION_VALUE/backendServices"
 sleep 40   
  curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{
      \"defaultService\": \"projects/$DEVSHELL_PROJECT_ID/regions/$REGION_VALUE/backendServices/blue-service\",
      \"hostRules\": [
        {
          \"hosts\": [
            \"*\"
          ],
          \"pathMatcher\": \"matcher1\"
        }
      ],
      \"name\": \"my-ilb\",
      \"pathMatchers\": [
        {
          \"defaultService\": \"regions/$REGION_VALUE/backendServices/blue-service\",
          \"name\": \"matcher1\",
          \"routeRules\": [
            {
              \"matchRules\": [
                {
                  \"prefixMatch\": \"/\"
                }
              ],
              \"priority\": 0,
              \"routeAction\": {
                \"weightedBackendServices\": [
                  {
                    \"backendService\": \"regions/$REGION_VALUE/backendServices/blue-service\",
                    \"weight\": 70
                  },
                  {
                    \"backendService\": \"regions/$REGION_VALUE/backendServices/green-service\",
                    \"weight\": 30
                  }
                ]
              }
            }
          ]
        }
      ],
      \"region\": \"projects/$DEVSHELL_PROJECT_ID/regions/$REGION_VALUE\"
    }" \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION_VALUE/urlMaps"
 sleep 40   
  curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{
      \"name\": \"my-ilb-target-proxy\",
      \"region\": \"projects/$DEVSHELL_PROJECT_ID/regions/$REGION_VALUE\",
      \"urlMap\": \"projects/$DEVSHELL_PROJECT_ID/regions/$REGION_VALUE/urlMaps/my-ilb\"
    }" \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION_VALUE/targetHttpProxies"
  sleep 40  
  curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{
      \"IPAddress\": \"10.10.30.5\",
      \"IPProtocol\": \"TCP\",
      \"allowGlobalAccess\": false,
      \"loadBalancingScheme\": \"INTERNAL_MANAGED\",
      \"name\": \"my-ilb-forwarding-rule\",
      \"networkTier\": \"PREMIUM\",
      \"portRange\": \"80\",
      \"region\": \"projects/$DEVSHELL_PROJECT_ID/regions/$REGION_VALUE\",
      \"subnetwork\": \"projects/$DEVSHELL_PROJECT_ID/regions/$REGION_VALUE/subnetworks/subnet-b\",
      \"target\": \"projects/$DEVSHELL_PROJECT_ID/regions/$REGION_VALUE/targetHttpProxies/my-ilb-target-proxy\"
    }" \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION_VALUE/forwardingRules"
pattern=(
"**********************************************************"
"**                 S U B S C R I B E  TO                **"
"**                 ABHI ARCADE SOLUTION                 **"
"**                                                      **"
"**********************************************************"
)

for line in "${pattern[@]}"
do
    echo -e "${YELLOW}${line}${NC}"
done
