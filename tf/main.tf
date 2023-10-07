provider "aws" {
  region = "us-east-1"
}


locals { 
value_vpc_id = var.vpc_id
value_keypair = var.keypair
value_ami_id = var.ami_id
}

terraform {
  backend "s3" {
    bucket = "hyperapp-tfstate"
    key    = "state/tfstate"
    region = "us-east-1"
  }
}

resource "aws_s3_bucket" "hyperapp_bucket" {
  bucket = "lg-hyperapp-5ec24429"
  acl    = "private"
}

#copy spec file to s3
#filemd5 hash is the always better way to copy file, it better to you absolute path 
resource "aws_s3_bucket_object" "k8_spec" {
  bucket = aws_s3_bucket.hyperapp_bucket.id 
  key    = "spec.yaml"
  source = "../spec.yaml"
  depends_on = [aws_s3_bucket.hyperapp_bucket]
}


#IAM policy
resource "aws_iam_policy" "hyperapp_policy2" {
  name        = "hyperapp-policy"
  description = "Access limited read obj from s3 and secerts"
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
        {
            "Sid" = "secerts",
            "Effect" = "Allow",
            "Action" = [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource" = "arn:aws:secretsmanager:us-east-1:981374845818:secret:HYPERSWITCH-ysZeRP"
        },
        ],
  })
}

resource "aws_iam_policy" "hyperapp_policy" {
  name        = "hyperapp-policy_s3"
  description = "Access limited read obj from s3 and secerts"
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
        {
            "Sid" = "s3",
            "Effect" = "Allow",
            "Action" = [
                "s3:ListBucket",
                "s3:GetObject"
            ],
            "Resource" = "arn:aws:s3:::lg-hyperapp-5ec24429"
        },
        {
            "Sid" = "s3obj",
            "Effect" = "Allow",
            "Action" = [
                "s3:ListBucket",
                "s3:GetObject"
            ],
            "Resource" = "arn:aws:s3:::lg-hyperapp-5ec24429/*"
        },
        ]
  })
}

#IAM ROLE
resource "aws_iam_role" "hyperapp_role" {
  name = "hyperapp-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com",
        },
      },
    ],
  })
}

# Attaching the IAM polixy to the role
 resource "aws_iam_policy_attachment" "hyper_role_polciy_attachment" {
    name = "hyperapp-policy-role-attachment"
    policy_arn = aws_iam_policy.hyperapp_policy.arn
    roles = [ aws_iam_role.hyperapp_role.name ]
 
}

 resource "aws_iam_policy_attachment" "hyper_role_polciy_attachment2" {
    name = "hyperapp-policy-role-attachment2"
    policy_arn = aws_iam_policy.hyperapp_policy2.arn
    roles = [ aws_iam_role.hyperapp_role.name ]

}

resource "aws_iam_instance_profile" "hyperapp_profile" {
  name = "hyperapp_profile"
  role = aws_iam_role.hyperapp_role.name
}

# I am  not createing vpc, ig, subnet and nat for this project 

resource "aws_security_group" "hyperapp_sg" {
  name        = "hyperapp-sg"
  description = "Security Group for SSH and HTTPS access"
  vpc_id      =  local.value_vpc_id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

resource "aws_instance" "hyperapp_instance" {
  ami           = local.value_ami_id
  instance_type = "t3a.medium"
  key_name      = local.value_keypair
  security_groups      = [aws_security_group.hyperapp_sg.name]
  iam_instance_profile = aws_iam_instance_profile.hyperapp_profile.name
  root_block_device {
    volume_size = 30 
  }
  user_data = <<EOF
#!/bin/bash
sudo apt install snapd
sudo snap install microk8s --classic
sudo aws s3 cp s3://lg-hyperapp-5ec24429/spec.yaml /home/ubuntu/spec.yaml
cd /home/ubuntu/
sudo touch one
sudo microk8s kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
sudo microk8s.kubectl apply -f spec.yaml
sudo touch /var/user_data_completei123
EOF
}
