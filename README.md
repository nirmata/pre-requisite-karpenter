# pre-requisite-karpenter
This Repo helps you to do pre requisite tasks that needs to be done karpenter.
This Repo can help you to Tag Subnet, Security Group which are used in your AWS EKS Cluster, Also it can create launch-template required for karpenter to provision nodes and it will also create NodeProfile, Policy ,Role for Karpenter Controller.

## Pre-Requisite
1. Make sure you have AWS-CLI installed.
2. Make sure you have sufficient permissions like create (Cloudformation-template, Create Tags, Describe EKS Clusters).

## Steps:
1. Clone Repo in your local
```git clone https://github.com/nirmata/pre-requisite-karpenter.git```

2. Navigate to karpenter-pre-req Dir
```cd karpenter-pre-req ```

3. add execution permission to bash-script
``` chmod +x karpenter-preprequisite-script.sh ```

4. This Script Requires cluster name as argument
```./karpenter-preprequisite-script.sh <clusterName> ```