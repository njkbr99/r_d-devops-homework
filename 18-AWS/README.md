# N18 — AWS Basics: VPC, Subnets, EC2, and Elastic IP

This homework demonstrates the creation of a fundamental AWS infrastructure using the AWS Management Console.
The setup includes a custom Virtual Private Cloud (VPC), public and private subnets, routing configuration via an Internet Gateway, security groups for access control, and a running EC2 instance with a static Elastic IP.

---

## Environment Overview

*   **Cloud Provider:** AWS
*   **Region:** eu-north-1 (Stockholm)
*   **Instance OS:** Amazon Linux 2
*   **Instance Type:** t3.micro
*   **Access Method:** SSH using RSA key (.pem)

---

## Step 1: Creating the VPC

A custom Virtual Private Cloud (VPC) was created to provide an isolated virtual network environment.

**Configuration:**
*   **Name:** `anat-vpc`
*   **IPv4 CIDR block:** `10.10.0.0/16`

![VPC Created](./screenshots/01_vpc_created.png)

---

## Step 2: Creating Subnets

Two subnets were created within the VPC to logically separate public-facing and private internal resources.

### Public Subnet
*   **Name:** `anat-public-subnet`
*   **CIDR:** `10.10.1.0/24`
*   **Purpose:** To host resources that require direct internet access (e.g., the EC2 instance).

![Public Subnet Created](./screenshots/02_public_subnet_created.png)

### Private Subnet
*   **Name:** `anat-private-subnet`
*   **CIDR:** `10.10.2.0/24`
*   **Purpose:** Reserved for internal services without direct internet exposure.

![Private Subnet Created](./screenshots/03_private_subnet_created.png)

---

## Step 3: Internet Gateway Configuration

An Internet Gateway (IGW) was created and attached to the VPC to enable communication between the VPC and the public internet.

*   **Gateway Name:** `anat-igw`

![IGW Created](./screenshots/04_igw_created.png)

The gateway was then explicitly attached to `anat-vpc`.

![IGW Attached](./screenshots/05_igw_attached.png)

---

## Step 4: Route Table Configuration

The VPC's main route table was updated to route all outbound traffic (0.0.0.0/0) through the newly created Internet Gateway.

**Routes:**
*   `10.10.0.0/16` → local (Traffic within the VPC)
*   `0.0.0.0/0` → `anat-igw` (External traffic via IGW)

![Route Table Updated](./screenshots/06_update_route_table_with_igw.png)

---

## Step 5: Public Subnet Settings

To ensure instances launched in the public subnet are reachable, the **Auto-assign public IPv4 address** setting was enabled.

![Auto-assign IPv4 Enabled](./screenshots/07_enable_auto_assign_public_ipv4.png)

---

## Step 6: Launching the EC2 Instance

An EC2 instance was launched using the Amazon Linux 2 AMI.

### 1. AMI Selection
The **Amazon Linux 2 AMI** (HVM, SSD Volume Type) was selected.

![AMI Selection](./screenshots/08_1_ec2_launch_ami_selection.png)

### 2. Instance Type and Key Pair
*   **Type:** `t3.micro` (Free tier eligible)
*   **Key Name:** `anat-key` (RSA, .pem format)

![Instance and Key Pair](./screenshots/08_2_ec2_launch_instance_and_key.png)

### 3. Network Settings
The instance was placed in the `anat-vpc` and `anat-public-subnet`.

![Network Settings](./screenshots/08_3_ec2_launch_networking_settings.png)

### 4. Security Group Rules
A new security group (`anat-sg`) was created with the following inbound rules:
*   **SSH (Port 22):** Allowed from any source (0.0.0.0/0)
*   **HTTP (Port 80):** Allowed from any source (0.0.0.0/0)

![Security Group Rules](./screenshots/08_4_ec2_launch_security_group_rules.png)

### 5. Launch Completion
The instance was successfully launched and reached the "Running" state.

![EC2 Launched](./screenshots/08_5_ec2_launched.png)

---

## Step 7: Elastic IP Configuration

An Elastic IP was allocated and associated with the EC2 instance to provide a persistent, static public IP address.

*   **Elastic IP:** `13.63.116.14`
*   **Associated Instance:** `i-02641e84ca00be2b7`

![Elastic IP Associated](./screenshots/09_elasticip_created_and_associated_with_instance.png)

---

## Step 8: Verifying SSH Connectivity

The EC2 instance was accessed from a local terminal via SSH using the private RSA key.

**Command:**
```powershell
ssh -i anat-key.pem ec2-user@13.63.116.14
```

Successful connection confirms that the routing, security group rules, and instance configuration are working as expected.

![SSH Connection](./screenshots/10_interesting_ssh_connect_from_windows.png)
