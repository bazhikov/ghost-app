resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.subnet_cloudx[0].id

  iam_instance_profile = aws_iam_instance_profile.ghost_app_profile.name

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "bastion-host"
  }

}