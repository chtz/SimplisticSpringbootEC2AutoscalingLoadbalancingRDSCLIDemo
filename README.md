# CAS Cloud 2015

## Simplistic Springboot EC2-Autoscaling-Loadbalancing-RDS-CLI-Demo

Deploy Springboot-based Demo Java-App to AWS (AutoScaling, Elastic Load Balancer, RDS) via AWS CLI script and demonstrate "reactive scaling" via CloudWatch Alarms. 

Demonstrates what can be done, not that it shall be done this way...

## Instructions

1.   Understand every single line in ec2/launch_aws_env.sh
2.   Adjust ec2/launch_aws_env.sh (e.g. choose unique S3 bucket name, ...)
3.   Ensure all dependencies are installed & configured (AWS CLI, AWS access- & secret key, AWS region, jq, ...)
4.   mvn clean install
5.   . ./ec2/launch_aws_env.sh
6.   Wait for script completion (and browse the Amazon Web Services Console in meanwhile: RDS, EC2, S3, CloudWatch, ...)
7.   Check for errors. There should be none. Otherwise, "cleanup the mess" (delete all $/h AWS resources)
8.   Expect answers from 2 web servers (try multiple times): curl http://$LB_DNS
9.   curl http://$LB_DNS?cmd=sleep&time=1000
10.  Generate some load (a few HTTP GETs every now and then). Wait for up-scaling
11.  Expect answers from 3 web servers (try multiple times): curl http://$LB_DNS
12.  curl http://$LB_DNS?cmd=sleep&time=50
13.  Generate some load (a few HTTP GETs every now and then). Wait for 2x down-scaling
14.  Expect answers from 1 web server (try multiple times): curl http://$LB_DNS
15.	 Cleanup the mess manually in the AWS Console: delete AWS RDS, AutoScaling Group, Load Balancer, SGs, Keys, S3,  Bucket, etc 
     (delete all $/h AWS resources)

## Troubleshooting

Works on my homebrew-powered OSX machine. Ask Google ;-) or browse the AWS docs...
