#!/bin/bash
CLUSTER_NAME=$1

tagging-resources(){
    SUBNET_IDS=$(aws eks describe-cluster --name $CLUSTER_NAME --output text | grep SUBNETIDS | awk '{print $2}')
    SECURITYGROUP_IDS=$(aws eks describe-cluster --name $CLUSTER_NAME --output text | grep SECURITYGROUPIDS | awk '{print $2}')
    CLUSTERSECURITYGROUP_IDS=$(aws eks describe-cluster --name $CLUSTER_NAME --output text | grep RESOURCESVPCCONFIG | awk '{print $2}')
    TAG_EKS=$(aws eks describe-cluster --name $CLUSTER_NAME --output text | grep arn | awk '{print $2}')
    ACCOUNT_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --output text | grep arn | awk '{print $2}' | cut -d ':' -f 5)

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

update-awsauth-cm(){
    echo "Updating awsauth configmap"
    eksctl create iamidentitymapping \
      --username system:node:{{EC2PrivateDNSName}} \
      --cluster  ${CLUSTER_NAME} \
      --arn "arn:aws:iam::${ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME}" \
      --group system:bootstrappers \
      --group system:nodes
}     

{
KarpenterController-IAM-Role(){
    echo "Creating KarpenterController IAM Role for the service account"
    eksctl create iamserviceaccount \
      --cluster "${CLUSTER_NAME}" --name karpenter --namespace karpenter \
      --role-name "${CLUSTER_NAME}-karpenter" \
      --attach-policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/KarpenterControllerPolicy-${CLUSTER_NAME}" \
      --role-only \
      --approve
}    

if [ -z "$CLUSTER_NAME" ]; then 
  echo "Provide Cluster Name as argument"; 
else 
  tagging-resources;
  launch-template;
  update-awsauth-cm;
  KarpenterController-IAM-Role;
fi
