resource "aws_key_pair" "mykey" {
  key_name   = "mykey"
  #public_key = "${file("${var.PATH_TO_PUBLIC_KEY}")}"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
}


resource "aws_instance" "project_instance" {
  ami           = "${lookup(var.AMIS, var.AWS_REGION)}" # Lookup value for AMI using map variable
  instance_type = "t3.micro"
  #key_name      = "$(aws_key_pair.mykey.key_name)"
  key_name      = aws_key_pair.mykey.key_name

  provisioner "remote-exec" {
     inline = [
       "sudo apt install python -y",
       "sudo apt install python-pip -y",
       "sudo pip install ansible"
      ]
  }
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    #private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
    private_key = file(var.PATH_TO_PRIVATE_KEY)
    timeout     = "4m"
  }
}

output "op1"{
value = aws_instance.project_instance.public_ip
}

resource "local_file" "ip" {
    content  = aws_instance.project_instance.public_ip
    filename = "ip.txt"
}

resource "aws_ebs_volume" "project_ebs"{
  availability_zone =  aws_instance.project_instance.availability_zone
  size              = 10
  tags = {
    Name = "myterraebs"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.project_ebs.id
  instance_id = aws_instance.project_instance.id
  force_detach = true
}

output "op2"{
value = aws_volume_attachment.ebs_att.device_name
}

resource "null_resource" "nullremote1" {
depends_on = [aws_instance.project_instance]
  connection {
    type        = "ssh"
    host        = aws_instance.project_instance.public_ip
    user        = "ubuntu"
    private_key = file(var.PATH_TO_PRIVATE_KEY)
    timeout     = "4m"
  }
 
  provisioner "remote-exec" {
    inline = [
        "sudo mkdir -p /root/ansible_terraform/aws_instance/ && sudo chown ubuntu: /root/ansible_terraform/aws_instance/"
  ]
  }

  provisioner "file" {
    source      = "ip.txt"
    destination = "/root/ansible_terraform/aws_instance/ip.txt"
  		   }
}

resource "null_resource" "nullremote2" {
depends_on = [aws_volume_attachment.ebs_att]
  connection {
    type        = "ssh"
    host        = aws_instance.project_instance.public_ip
    user        = "ubuntu"
    private_key = file(var.PATH_TO_PRIVATE_KEY)
    timeout     = "4m"
  }
  provisioner "remote-exec" {
    
    inline = [
        "sudo chown -R root: /root/ansible_terraform/aws_instance/",
	"sudo cd /root/ansible_terraform/aws_instance/",
	"sudo ansible-playbook install_software.yml"
]
}
}
