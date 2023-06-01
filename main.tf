resource "aws_vpc" "dev_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "dev_pub_subnet" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev-public"
  }
}

resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id
  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "dev_rt" {
  vpc_id = aws_vpc.dev_vpc.id
  tags = {
    Name = "dev-rt"
  }
}

resource "aws_route" "default-route" {
  route_table_id         = aws_route_table.dev_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dev_igw.id
}

resource "aws_route_table_association" "dev_pub_assoc" {
  subnet_id      = aws_subnet.dev_pub_subnet.id
  route_table_id = aws_route_table.dev_rt.id
}

resource "aws_security_group" "dev-sg" {
  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.dev_vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_key_pair" "dev_keypair" {
  key_name   = "dev_terraform"
  public_key = file("~/.ssh/dev-terraform.pub")
}

resource "aws_instance" "dev_node" {
  instance_type = "t2.micro"
  ami = data.aws_ami.server_ami.id
  key_name = aws_key_pair.dev_keypair.id
  vpc_security_group_ids = [ aws_security_group.dev-sg.id ]
  subnet_id = aws_subnet.dev_pub_subnet.id
  user_data = file("userdata.tpl")
  tags = {
    Name = "dev-node"
  }
}