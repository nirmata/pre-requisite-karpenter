#!/bin/bash
CLUSTER_NAME=$1

tagging-resources(){
    TAG_EKS=$(aws eks describe-cluster --name $CLUSTER_NAME --output text | grep arn | awk '{print $2}')
    ACCOUNT_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --output text | grep arn | awk '{print $2}' | cut -d ':' -f 5)
    
    aws eks tag-resource --resource-arn $TAG_EKS --tags Key="karpenter.sh/discovery",Value=$CLUSTER_NAME
    echo "----- EKS Cluster is tagged -----"
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
  update-awsauth-cm;
  KarpenterController-IAM-Role;
fi
