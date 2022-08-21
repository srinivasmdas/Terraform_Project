# Terraform_Project
Work &amp; Implement Terraform Project Usecases.


Write Up on the Code workflow:
=============================
File: ansible.cfg
Contains privilege escalation information for ansible to become:root user when installing certain packages.
File: install_software.yml
Is the actual ansible playbook that will install the packages like java, Jenkins and starts the Jenkins service.
File: instance.tf
Is the actual terraform file where:
1. Keypair is created - mykey
2. Ec2 instance is created - "project_instance”
1. IP of EC2 instance is stored in "op1"
2. Value of IP is copied to "ip.txt"
3. EBS volume is created - "project_ebs"
4. EBS volume is attached as /dev/sdh - "ebs_att"
3. Then, there is list of provisioners.
1. File provisioners are used to copy files to remote
2. Remote-exec provisioners are used to execute a command on
remote host.
"ansible-playbook /opt/ansi-terraform/install_software.yml --ssh-
common-args='-o StrictHostKeyChecking=no'"
