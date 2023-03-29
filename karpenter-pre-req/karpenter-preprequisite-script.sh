#!/bin/bash
CLUSTER_NAME=$1

tagging-resources(){
    SUBNET_IDS=$(aws eks describe-cluster --name $CLUSTER_NAME --output text | grep SUBNETIDS | awk '{print $2}')
    SECURITYGROUP_IDS=$(aws eks describe-cluster --name $CLUSTER_NAME --output text | grep SECURITYGROUPIDS | awk '{print $2}')
    CLUSTERSECURITYGROUP_IDS=$(aws eks describe-cluster --name $CLUSTER_NAME --output text | grep RESOURCESVPCCONFIG | awk '{print $2}')
    TAG_EKS=$(aws eks describe-cluster --name $CLUSTER_NAME --output text | grep arn | awk '{print $2}')

    aws ec2 create-tags --resources $SUBNET_IDS --tags Key="karpenter.sh/discovery",Value=$CLUSTER_NAME
    echo "----- Subnet are tagged -----"

    aws ec2 create-tags --resources $SECURITYGROUP_IDS --tags Key="karpenter.sh/discovery",Value=$CLUSTER_NAME
    aws ec2 create-tags --resources $CLUSTERSECURITYGROUP_IDS --tags Key="karpenter.sh/discovery",Value=$CLUSTER_NAME
    echo "----- SecurityGroups are tagged -----"
    
    aws eks tag-resource --resource-arn $TAG_EKS --tags Key="karpenter.sh/discovery",Value=$CLUSTER_NAME
    echo "----- EKS Cluster is tagged -----"
}

launch-template(){
    echo "Creating Launch Template"
    aws cloudformation create-stack \
      --stack-name ${CLUSTER_NAME}-launch-template \
      --template-body file://./karpenter-launch-template.yaml \
      --parameters ParameterKey=ClusterName,ParameterValue=${CLUSTER_NAME} ParameterKey=SecurityGroups,ParameterValue=\"${SECURITYGROUP_IDS},${CLUSTERSECURITYGROUP_IDS}\"

    echo "Creating Karpenter NodeProfile, Policy, Role"
    aws cloudformation create-stack \
      --stack-name ${CLUSTER_NAME}-karpenter \
      --template-body file://./karpenter-policy.yaml \
      --capabilities CAPABILITY_NAMED_IAM \
      --parameters ParameterKey=ClusterName,ParameterValue=${CLUSTER_NAME}
}   

if [ -z "$CLUSTER_NAME" ]; then 
  echo "Provide Cluster Name as argument"; 
else 
  tagging-resources;
  launch-template;
fi
