#!/bin/bash
CLUSTER_NAME=$1
ACCOUNT_ID=$2

update-awsauth-cm(){
    echo "Updating awsauth configmap"  
    eksctl create iamidentitymapping \
      --region us-west-1 \
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
      --region us-west-1 \
      --cluster "${CLUSTER_NAME}" --name karpenter --namespace karpenter \
      --role-name "${CLUSTER_NAME}-karpenter" \
      --attach-policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/KarpenterControllerPolicy-${CLUSTER_NAME}" \
      --role-only \
      --approve
}    

if [ $# -lt 2  ]; then 
  echo "Provide Cluster Name and Account ID as arguments"; 
else 
  update-awsauth-cm;
  KarpenterController-IAM-Role;
fi
