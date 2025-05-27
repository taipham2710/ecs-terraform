# modules/jenkins/main.tf
resource "aws_instance" "jenkins" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.security_group_id]
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  availability_zone           = var.availability_zone
  user_data                   = file("${path.module}/userdata.sh")

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-jenkins-server"
  }
}