data "aws_vpc" "default" {
  default = true
}

# Create a security group that allows SSH
resource "aws_security_group" "kapil_sg" {
  name        = "kapil-allow-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id 

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allowing ingress http port"
    # Type        = "Custom TCP"
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allowing ingress https port"
    # Type        = "Custom TCP"
    from_port   = 30443
    to_port     = 30443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kapil-allow-ssh"
  }
}

# create a key-pair
resource "aws_key_pair" "kapil_key" {
    key_name = "kapil-server"
    public_key = file("~/.ssh/id_rsa.pub")
}

# creating ec2 instance
resource "aws_instance" "kapil-instance" {
    ami     =   "ami-0fc5d935ebf8bc3bc"  # Ubuntu 22.04 LTS
    instance_type = "t3.medium"
    key_name = aws_key_pair.kapil_key.key_name
    security_groups = [aws_security_group.kapil_sg.name]

    tags = {
        Name = "kapil-server"
    }

    user_data = templatefile("${path.module}/install_tools.sh", {})
    # for solving issue of:
    # script execution before completely boot up of instance.
    # Waits until EC2 passes both system and instance status checks.
    # This ensures:
    # Networking is up, OS booted, Cloud-init probably done or near completion
    provisioner "local-exec" {
        command = "aws ec2 wait instance-status-ok --instance-ids ${self.id} --region us-east-1"
    }
}

output "instance_public_ip" {
  value = aws_instance.kapil-instance.public_ip
}