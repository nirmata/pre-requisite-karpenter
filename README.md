# pre-requisite-karpenter
This Repo helps you to do pre requisite tasks that needs to be done karpenter.
This Repo can help you to Tag Subnet, Security Group which are used in your AWS EKS Cluster, Also it can create launch-template required for karpenter to provision nodes and it will also create NodeProfile, Policy ,Role for Karpenter Controller.

## Pre-Requisite
1. Should have EKS cluster in Nirmata
2. EKS Cluster should be enabled with `IAM Role for ServiceAccount`

## Steps
1. Go To **Clusters** > **Clusters**, Click on your EKS Cluster.
2. **Settings** > Cloud, Here Add **IAM Role**.
3. Provide **Role Name**, select **Namespace** and **ServiceAccount** as **Default**. Select `AWSCloudFormationFullAccess, AmazonEC2FullAccess, IAMFullAccess, eks-access-full` and click **Add**.
4. Go to **Workload** > **Catalog**, Click on **Add Catalog**.
5. Give it **Name** and Click on **Add Catalog**.
6. Click on **Add Application**, Give it **Name**.
7. Select Type **git**,Add Repository `https://github.com/nirmata/pre-requisite-karpenter.git` and Click **Save**.
8. Click on **Run Application**, Click on More Options, look for default-<your-cluster-name> select it.
9. Close More Options window and Click on **Run**.