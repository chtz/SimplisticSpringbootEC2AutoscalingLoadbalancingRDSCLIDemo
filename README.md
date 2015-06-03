# CAS Cloud 2015

## Simplistic Springboot EC2-Autoscaling-Loadbalancing-RDS-CLI-Demo

Deploy Springboot-based Demo Java-App to AWS (AutoScaling, Elastic Load Balancer, RDS) via AWS CLI script and demonstrate "reactive scaling" via CloudWatch Alarms. 

Demonstrates what can be done, not that it shall be done this way...

## Instructions

1.   Understand every single line in ec2/launch_aws_env.sh
2.   Adjust ec2/launch_aws_env.sh (e.g. choose unique S3 bucket name, ...)
3.   Ensure all dependencies are installed & configured (AWS CLI, AWS access- & secret key, AWS region, jq, ...)
4.	 Understand ec2/cloudinit.sh
5.   Adjust ec2/cloudinit.sh (e.g. S3 bucket name)
6.   mvn clean install
7.   . ./ec2/launch_aws_env.sh
8.   Wait for script completion (and browse the Amazon Web Services Console in meanwhile: RDS, EC2, S3, CloudWatch, ...)
9.   Check for errors. There should be none. Otherwise, "cleanup the mess" (delete all $/h AWS resources)
10.  Expect answers from 2 web servers (try multiple times): curl http://$LB_DNS
11.  curl http://$LB_DNS?cmd=sleep&time=1000
12.  Generate some load (a few HTTP GETs every now and then). Wait for up-scaling
13.  Expect answers from 3 web servers (try multiple times): curl http://$LB_DNS
14.  curl http://$LB_DNS?cmd=sleep&time=50
15.  Generate some load (a few HTTP GETs every now and then). Wait for 2x down-scaling
16.  Expect answers from 1 web server (try multiple times): curl http://$LB_DNS
17.	 Cleanup the mess manually in the AWS Console: delete AWS RDS, AutoScaling Group, Load Balancer, SGs, Keys, S3,  Bucket, etc 
     (delete all $/h AWS resources)

## Troubleshooting

Works on my homebrew-powered OSX machine. Ask Google ;-) or browse the AWS docs...
