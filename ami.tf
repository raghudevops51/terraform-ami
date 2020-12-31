resource "aws_instance" "ami-instance" {
  ami                     = data.aws_ami.ami.id
  instance_type           = "t3.medium"
  vpc_security_group_ids  = [aws_security_group.allow-ssh-for-ami.id]
}

resource "null_resource" "apply" {
  provisioner "remote-exec" {
    connection {
      host      = aws_instance.ami-instance.public_ip
      user      = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)["SSH_USER"]
      password  = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)["SSH_PASS"]
    }
    inline = [
      "sudo pip install ansible",
      "echo localhost >/tmp/hosts",
      "ansible-pull -i /tmp/hosts -U https://DevOps-Batches@dev.azure.com/DevOps-Batches/DevOps51/_git/ansible roboshop.yml -t ${var.component} -e component=${var.component} -e PAT=${var.PAT} -e ENV=${var.ENV} -e MONGO_ENDPOINT=mongo-${var.ENV}.devopsb51.tk -e REDIS_ENDPOINT=redis-${var.ENV}.devopsb51.tk -e CATALOGUE_ENDPOINT=catalogue-${var.ENV}.devopsb51.tk -e CART_HOST=cart-${var.ENV}.devopsb51.tk -e USER_HOST=user-${var.ENV}.devopsb51.tk -e AMQP_HOST=rabbitmq-${var.ENV}.devopsb51.tk -e CART_ENDPOINT=cart-${var.ENV}.devopsb51.tk -e DB_HOST=mysql-${var.ENV}.devopsb51.tk -e CATALOGUE_PORT=80 -e CART_PORT=80 -e USER_PORT=80"
    ]
  }
}

resource "aws_security_group" "allow-ssh-for-ami" {
  name        = "allow-ssh-for-ami-${var.component}"
  description = "allow-ssh-for-ami-${var.component}"

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh-for-ami-${var.component}"
  }
}

module "files" {
  source  = "matti/resource/shell"
  command = "date +%s"
}


resource "aws_ami_from_instance" "ami" {
  depends_on          = [null_resource.apply]
  name                = "${var.component}-${var.ENV}-${module.files.stdout}"
  source_instance_id  = aws_instance.ami-instance.id
}