# V1 - Single-AZ Public Web Server

## 1. Project Overview

V1 builds a basic AWS Web Server environment in a single Availability Zone.

The final environment contains:

- One VPC
- One Public Subnet
- One Internet Gateway
- One Public Route Table
- One Security Group
- Default Network ACL
- One EC2 instance
- One Public IPv4 address
- SSH access
- Nginx Web Server

The final architecture is:

```text
User / Browser
      |
      v
   Internet
      |
      v
Internet Gateway
      |
      v
VPC
10.0.0.0/16
      |
      v
Public Subnet
10.0.1.0/24
      |
      v
EC2
Amazon Linux 2023
      |
      +-- SSH TCP 22
      |
      +-- Nginx TCP 80
```

The network configuration is:

| Resource           | Configuration                |
| ------------------ | ---------------------------- |
| Region             | us-east-1                    |
| Availability Zone  | us-east-1a                   |
| VPC CIDR           | 10.0.0.0/16                  |
| Public Subnet CIDR | 10.0.1.0/24                  |
| Internet Route     | 0.0.0.0/0 → Internet Gateway |
| HTTP               | TCP 80                       |
| SSH                | TCP 22 **from My IP**        |
| Architecture       | Single-AZ                    |

---

# 2. Create and Configure the AWS Account

## 2.1 Create the AWS Account

Create a new AWS Account and complete the account registration process.

Confirm that the AWS Management Console can be accessed successfully.

---

## 2.2 Configure the Root User

Configure the Root User.

| Configuration        | Setting     |
| -------------------- | ----------- |
| Root Password        | Configured  |
| MFA                  | Enabled     |
| Access Key           | Not created |
| Daily Administration | Not used    |

The Root User is kept for account-level operations only.

---

## 2.3 Create the Administrator User

Create an IAM User for daily administration.

| Configuration                 | Setting             |
| ----------------------------- | ------------------- |
| User Name                     | lab-admin           |
| AWS Management Console Access | Enabled             |
| Permission                    | AdministratorAccess |
| MFA                           | Enabled             |
| Access Key                    | Not created         |

Use lab-admin for the daily V1 deployment work.

---

## 2.4 Confirm the AWS Region

Set the AWS Console Region to:

| Configuration | Setting             |
| ------------- | ------------------- |
| Region Name   | US East N. Virginia |
| Region Code   | us-east-1           |

All V1 regional resources are created in us-east-1.

---

# 3. Create the VPC

Create a new VPC.

| Configuration          | Setting          |
| ---------------------- | ---------------- |
| Resources to create    | VPC only         |
| Name                   | aws-prod-lab-vpc |
| IPv4 CIDR              | 10.0.0.0/16      |
| IPv6 CIDR              | None             |
| Tenancy                | Default          |
| VPC Encryption Control | None             |

The VPC address range is:10.0.0.0/16

All V1 subnets are created inside this address range.

---

# 4. Create the Public Subnet

Create one subnet inside aws-prod-lab-vpc.

| Configuration     | Setting          |
| ----------------- | ---------------- |
| Name              | public-subnet-a1 |
| VPC               | aws-prod-lab-vpc |
| Availability Zone | us-east-1a       |
| IPv4 CIDR         | 10.0.1.0/24      |

The network structure is:

```text
aws-prod-lab-vpc
10.0.0.0/16
      |
      +-- public-subnet-a1
          10.0.1.0/24
          us-east-1a
```

---

# 5. Create the Internet Gateway

Create an Internet Gateway.

| Configuration | Setting          |
| ------------- | ---------------- |
| Name          | aws-prod-lab-igw |

Attach the Internet Gateway to: aws-prod-lab-vpc

After the attachment is complete, the Internet Gateway belongs to the V1 VPC.

---

# 6. Create the Public Route Table

Create a Route Table.

| Configuration | Setting          |
| ------------- | ---------------- |
| Name          | public-rt        |
| VPC           | aws-prod-lab-vpc |

The Route Table automatically contains the VPC local route.

Add the Internet route.

| Destination | Target           |
| ----------- | ---------------- |
| 10.0.0.0/16 | local            |
| 0.0.0.0/0   | aws-prod-lab-igw |

Associate public-rt with: public-subnet-a1

The final routing relationship is:

```text
public-subnet-a1
      |
      v
public-rt
      |
      +-- 10.0.0.0/16 → local
      |
      +-- 0.0.0.0/0 → aws-prod-lab-igw
```

---

# 7. Create the Security Group

Create a Security Group for the EC2 Web Server.

| Configuration | Setting          |
| ------------- | ---------------- |
| Name          | web-sg           |
| VPC           | aws-prod-lab-vpc |

Configure the Inbound Rules.

| Type | Protocol | Port | Source        |
| ---- | -------- | ---- | ------------- |
| HTTP | TCP      | 80   | 0.0.0.0/0     |
| SSH  | TCP      | 22   | **My IP /32** |

Keep the default Outbound Rule.

| Type        | Protocol | Port | Destination |
| ----------- | -------- | ---- | ----------- |
| All Traffic | All      | All  | 0.0.0.0/0   |

HTTP is available from the Internet.

SSH is available only from the administrator public IP.

---

# 8. Check the Network ACL

Open the Network ACL associated with public-subnet-a1.

V1 uses the Default Network ACL.

Confirm that the Default Network ACL is associated with public-subnet-a1.

The default Network ACL allows all inbound and outbound traffic.

| Direction | Rule      |
| --------- | --------- |
| Inbound   | Allow All |
| Outbound  | Allow All |

No Custom Network ACL is created in V1.

---

# 9. Create the EC2 Key Pair

Create an EC2 Key Pair.

| Configuration      | Setting    |
| ------------------ | ---------- |
| Name               | v1-web-key |
| Key Type           | RSA        |
| Private Key Format | .pem       |

Save the downloaded private key on the Mac.

Recommended location: ~/.ssh/v1-web-key.pem

Set the file permission: chmod 400 ~/.ssh/v1-web-key.pem

The private key is used later for SSH authentication.

---

# 10. Create the EC2 Instance

Create the EC2 Web Server.

| Configuration         | Setting           |
| --------------------- | ----------------- |
| Name                  | v1-web-server     |
| AMI                   | Amazon Linux 2023 |
| Architecture          | 64-bit x86        |
| Instance Type         | t3.micro          |
| Key Pair              | v1-web-key        |
| VPC                   | aws-prod-lab-vpc  |
| Subnet                | public-subnet-a1  |
| Auto-assign Public IP | Enable            |
| Security Group        | web-sg            |
| Root Volume           | 8 GiB gp3         |
| IAM Instance Profile  | None              |
| User Data             | None              |
| Elastic IP            | None              |

Launch the instance.

Wait until the Instance State becomes Running.

Confirm that the Status Checks pass.

---

# 11. Verify the EC2 Network Configuration

Open the EC2 Instance Summary.

Confirm the following values.

| Check             | Expected Result  |
| ----------------- | ---------------- |
| Instance State    | Running          |
| VPC               | aws-prod-lab-vpc |
| Subnet            | public-subnet-a1 |
| Availability Zone | us-east-1a       |
| Private IPv4      | 10.0.1.x         |
| Public IPv4       | Assigned         |
| Security Group    | web-sg           |
| Instance Type     | t3.micro         |
| Status Checks     | Passed           |

The Private IPv4 is assigned from the public-subnet-a1 CIDR.

The Public IPv4 is automatically assigned by AWS.

---

# 12. Connect to EC2 with SSH

Amazon Linux uses the default user: ec2-user

Connect from the Mac Terminal. ssh -i ~/.ssh/v1-web-key.pem ec2-user@public-ip

On the first connection, verify the SSH Host Fingerprint and accept the host.

Confirm the current user and directory if necessary.

whoami

pwd

---

# 13. Update Amazon Linux

Update the operating system packages.

sudo dnf update -y

Amazon Linux 2023 uses dnf as the package manager.

---

# 14. Install Nginx

Install Nginx: sudo dnf install nginx -y

Start Nginx: sudo systemctl start nginx

Enable Nginx at boot: sudo systemctl enable nginx

Check the service status: sudo systemctl status nginx

Confirm that Nginx is Running.

---

# 15. Test Nginx Locally

Test the Web Server from inside the EC2 instance.

curl http://localhost

A successful response returns the Nginx HTML page.

This confirms that Nginx can process HTTP requests locally.

---

# 16. Check Listening Ports

Run: sudo ss -lntp

Confirm that Nginx and SSH are listening.

Example:

```text
0.0.0.0:80    nginx
0.0.0.0:22    sshd
[::]:80       nginx
[::]:22       sshd
```

0.0.0.0:80 means Nginx is listening on TCP 80 on all local IPv4 addresses.

0.0.0.0:22 means sshd is listening on TCP 22 on all local IPv4 addresses.

[::] represents the corresponding IPv6 listener.

---

# 17. Test the Website from the Internet

Open the EC2 Instance Summary and find the current Public IPv4 address.

Open a browser on the Mac.

Access: http://PUBLIC-IP

Confirm that the Nginx Welcome Page is displayed.

This verifies the complete HTTP path from the Internet to the EC2 Web Server.

The final traffic path is:

```text
User / Browser
      |
      v
Internet
      |
      v
Internet Gateway
      |
      v
aws-prod-lab-vpc
      |
      v
public-subnet-a1
      |
      v
EC2 ENI
      |
      v
web-sg
      |
      v
Nginx TCP 80
      |
      v
HTTP Response
```

---

# 18. Verify the Final V1 Environment

Confirm the AWS network configuration.

| Check                          | Result |
| ------------------------------ | ------ |
| VPC                            | Passed |
| VPC CIDR 10.0.0.0/16           | Passed |
| Public Subnet                  | Passed |
| Subnet CIDR 10.0.1.0/24        | Passed |
| Subnet in us-east-1a           | Passed |
| Internet Gateway Attached      | Passed |
| Local Route                    | Passed |
| 0.0.0.0/0 → IGW                | Passed |
| Subnet Route Table Association | Passed |
| Security Group HTTP Rule       | Passed |
| Security Group SSH Rule        | Passed |
| Default Network ACL            | Passed |

Confirm the EC2 and Linux configuration.

| Check                 | Result |
| --------------------- | ------ |
| EC2 Running           | Passed |
| Public IPv4 Assigned  | Passed |
| SSH Login             | Passed |
| Amazon Linux Running  | Passed |
| Nginx Installed       | Passed |
| Nginx Running         | Passed |
| Nginx Enabled         | Passed |
| TCP 80 Listening      | Passed |
| TCP 22 Listening      | Passed |
| curl localhost        | Passed |
| Browser Public Access | Passed |

V1 deployment is complete.

---

# 19. Basic Troubleshooting

## 19.1 SSH Timeout

If SSH times out, check:

1. EC2 Instance State
2. Public IPv4
3. Internet Gateway attachment
4. Route Table
5. Subnet association
6. Security Group TCP 22
7. Current administrator Public IP
8. EC2 Status Checks

---

## 19.2 SSH Permission Denied

If SSH returns Permission Denied, check:

1. SSH Private Key
2. EC2 Username
3. EC2 Key Pair
4. Private Key file permission

---

## 19.3 SSH Works but Website Does Not Work

Check the Nginx service.

sudo systemctl status nginx

Check TCP 80.

sudo ss -lntp

Test locally.

curl http://localhost

If the local test works, continue checking the AWS network configuration.

---

## 19.4 Local Nginx Works but Internet Access Fails

If curl localhost works but the browser cannot access the website, check:

1. Nginx listening address
2. Security Group TCP 80
3. Public IPv4
4. Route Table
5. Internet Gateway
6. Network ACL

If Nginx listens only on:

127.0.0.1:80

the service is available only through the local Loopback Interface.

For this V1 Web Server, Nginx listens on:

0.0.0.0:80

---

# 20. Final V1 Architecture

```text
Internet
   |
   v
Internet Gateway
aws-prod-lab-igw
   |
   v
VPC
aws-prod-lab-vpc
10.0.0.0/16
   |
   v
Public Subnet
public-subnet-a1
10.0.1.0/24
us-east-1a
   |
   +-- public-rt
   |   |
   |   +-- 10.0.0.0/16 → local
   |   |
   |   +-- 0.0.0.0/0 → Internet Gateway
   |
   +-- Default Network ACL
   |
   +-- EC2
       v1-web-server
       Amazon Linux 2023
       t3.micro
       |
       +-- web-sg
       |   |
       |   +-- HTTP TCP 80 ← 0.0.0.0/0
       |   |
       |   +-- SSH TCP 22 ← My IP /32
       |
       +-- sshd TCP 22
       |
       +-- nginx TCP 80
```

V1 Single-AZ Public Web Server deployment is complete.