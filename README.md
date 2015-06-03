# CAS Cloud 2015

## Simplistic Springboot EC2-Autoscaling-Loadbalancing-RDS-CLI-Demo

Deploy Springboot-based Demo Java-App to AWS (AutoScaling, Elastic Load Balancer, RDS) via AWS CLI script and demonstrate "reactive scaling" via CloudWatch Alarms. 

Demonstrates what can be done, not that it shall be done this way...

## Instructions

1.   Understand every single line in ec2/launch_aws_env.sh
1.1. Adjust ec2/launch_aws_env.sh (e.g. choose unique S3 bucket name, ...)
1.2. Ensure all dependencies are installed & configured (AWS CLI, AWS access- & secret key, AWS region, jq, ...)
2.	 Understand ec2/cloudinit.sh
2.1. Adjust ec2/cloudinit.sh (e.g. S3 bucket name)
3.   mvn clean install
4.   . ./ec2/launch_aws_env.sh
5.   Wait for script completion (and browse the Amazon Web Services Console in meanwhile: RDS, EC2, S3, CloudWatch, ...)
5b.  Check for errors. There should be none. Otherwise, "cleanup the mess" ($/h AWS resources).
6.   Expect answers from 2 web servers (try multiple times): curl http://$LB_DNS
7.   curl http://$LB_DNS?cmd=sleep&time=1000
8.   Wait for up-scaling
9.   Expect answers from 3 web servers (try multiple times): curl http://$LB_DNS
10.  curl http://$LB_DNS?cmd=sleep&time=50
11.  Wait for 2x down-scaling
12.  Expect answers from 1 web server (try multiple times): curl http://$LB_DNS
13.	 Cleanup the mess _manually_ in the AWS Console (delete $/h AWS RDS, AutoScaling Group, Load Balancer, SGs, Keys, S3,  Bucket, etc.)

## Troubleshooting

Works on my homebrew-powered OSX machine. Ask Google ;-) or browse the AWS docs...
