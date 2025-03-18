# Payment Processing API Deployment

This document provides step-by-step instructions to deploy the **Payment Processing API** on AWS using the AWS CLI. It also covers setting up GitHub Actions for CI/CD and validating the deployment.

---

## **1. AWS CLI Deployment Commands**

### **1.1 Create VPC and Subnets**
```sh
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=payment-vpc},{Key=Application,Value=Payment-Processing}]'
```
✔ **Save `VpcId` as `VPC_ID`**.

```sh
aws ec2 create-subnet --vpc-id <VPC_ID> --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-1a},{Key=Application,Value=Payment-Processing}]'
```
✔ **Save `SubnetId` as `PUBLIC_SUBNET_1_ID`**.

```sh
aws ec2 create-subnet --vpc-id <VPC_ID> --cidr-block 10.0.3.0/24 --availability-zone us-east-1b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-1b},{Key=Application,Value=Payment-Processing}]'
```
✔ **Save `SubnetId` as `PUBLIC_SUBNET_2_ID`**.

```sh
aws ec2 create-subnet --vpc-id <VPC_ID> --cidr-block 10.0.2.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-1a},{Key=Application,Value=Payment-Processing}]'
```
✔ **Save `SubnetId` as `PRIVATE_SUBNET_1_ID`**.

```sh
aws ec2 create-subnet --vpc-id <VPC_ID> --cidr-block 10.0.4.0/24 --availability-zone us-east-1b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-1b},{Key=Application,Value=Payment-Processing}]'
```
✔ **Save `SubnetId` as `PRIVATE_SUBNET_2_ID`**.

### **1.2 Create Internet Gateway and Routing**
```sh
aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=payment-igw},{Key=Application,Value=Payment-Processing}]'
```
✔ **Save `InternetGatewayId` as `IGW_ID`**.

```sh
aws ec2 attach-internet-gateway --vpc-id <VPC_ID> --internet-gateway-id <IGW_ID>
```

### **1.3 Create Route Table**
```sh
aws ec2 create-route-table --vpc-id <VPC_ID> --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=public-rtb},{Key=Application,Value=Payment-Processing}]'
```
✔ **Save `RouteTableId` as `PUBLIC_RTB_ID`**.

```sh
aws ec2 create-route --route-table-id <PUBLIC_RTB_ID> --destination-cidr-block 0.0.0.0/0 --gateway-id <IGW_ID>
```

```sh
aws ec2 associate-route-table --route-table-id <PUBLIC_RTB_ID> --subnet-id <PUBLIC_SUBNET_1_ID>
```

```sh
aws ec2 associate-route-table --route-table-id <PUBLIC_RTB_ID> --subnet-id <PUBLIC_SUBNET_2_ID>
```

---

## **2. Create and Deploy Custom AMI**
### **2.1 Launch AMI Builder Instance**
```sh
aws ec2 run-instances --image-id ami-0abcdef1234567890 --instance-type t3.micro --subnet-id <PUBLIC_SUBNET_1_ID> --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ami-builder-instance},{Key=Application,Value=Payment-Processing}]'
```
✔ **Save `InstanceId` as `BUILDER_INSTANCE_ID`**.

### **2.2 Create AMI**
```sh
aws ec2 create-image --instance-id <BUILDER_INSTANCE_ID> --name "payment-api-ami" --no-reboot
```
✔ **Save `ImageId` as `AMI_ID`**.

---

## **3. Deploy EC2 Instances and Load Balancer**

### **3.1 Launch EC2 Instances**
```sh
aws ec2 run-instances --image-id <AMI_ID> --instance-type t3.small --subnet-id <PRIVATE_SUBNET_1_ID> --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=payment-server-1a},{Key=Role,Value=Payment-Server}]'
```
✔ **Save `InstanceId` as `INSTANCE_1_ID`**.

```sh
aws ec2 run-instances --image-id <AMI_ID> --instance-type t3.small --subnet-id <PRIVATE_SUBNET_2_ID> --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=payment-server-1b},{Key=Role,Value=Payment-Server}]'
```
✔ **Save `InstanceId` as `INSTANCE_2_ID`**.

---

## **4. GitHub Secrets Setup**

To deploy using GitHub Actions, set up **GitHub Secrets**:
1. Go to **GitHub Repository → Settings → Secrets and Variables → Actions**.
2. Click **New repository secret** and add the following:
   - **AWS_ACCESS_KEY_ID**: `<Your AWS Access Key>`
   - **AWS_SECRET_ACCESS_KEY**: `<Your AWS Secret Key>`

---

## **5. Validate Deployment**
### **5.1 Get ALB DNS Name**
```sh
aws elbv2 describe-load-balancers --names payment-alb --query "LoadBalancers[0].DNSName" --output text
```
✔ **Save the ALB DNS name as `ALB_DNS`**.

### **5.2 Test API Endpoint**
```sh
curl http://<ALB_DNS>
```
✔ Expected Output:
```json
{ "status": "Payment Processed", "timestamp": "2025-03-17T12:34:56Z" }
```

---

## **6. CI/CD with GitHub Actions**
Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy Payment API

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Deploy Infrastructure
        run: bash scripts/deploy.sh
```

---

## **Conclusion**
This setup provisions a secure **Payment Processing API** infrastructure on AWS, deploys an **Application Load Balancer (ALB)**, and automates deployments via **GitHub Actions**.
