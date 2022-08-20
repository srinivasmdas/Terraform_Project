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
       "sudo yum update -y",
       "sudo amazon-linux-extras install ansible2 -y",
       "sudo ansible --version"
      ]
  }
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
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
    user        = "ec2-user"
    private_key = file(var.PATH_TO_PRIVATE_KEY)
    timeout     = "4m"
  }
 
  provisioner "remote-exec" {
    inline = [
        "sudo mkdir -p /opt/ansi-terraform",
        "sudo chmod 777 /opt/ansi-terraform",
         
  ]
  }

  provisioner "file" {
    source      = "ip.txt"
    destination = "/opt/ansi-terraform/ip.txt"
  		   }
}

resource "null_resource" "nullremote2" {
depends_on = [aws_volume_attachment.ebs_att]
  connection {
    type        = "ssh"
    host        = aws_instance.project_instance.public_ip
    user        = "ec2-user"
    private_key = file(var.PATH_TO_PRIVATE_KEY)
    timeout     = "4m"
  }
 
  
  provisioner "remote-exec" {
    
    inline = [
        "sudo chown -R root: /opt/ansi-terraform/",
	"cd /opt/ansi-terraform/"
       ]
    }

  provisioner "remote-exec" {
    
    inline = [
	"ansible-playbook install_software.yaml"
    ]
   }
}
