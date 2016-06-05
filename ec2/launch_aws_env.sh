#!/bin/bash

#Hint: Execute manually, step by step (due to lacking error- and incomplete wait- and retry-handling)

#Pre-cond: Linux/OSX-Environment (with the usual tools installed, à la wget, curl, ...)
#Pre-cond: jq installed (http://stedolan.github.io/jq/ - or brew install jq)

#Pre-cond: AWS CLI installed (JSON output & access keys configured)
#          export AWS_DEFAULT_REGION=FIXME
#          export AWS_ACCESS_KEY_ID=FIXME
#          export AWS_SECRET_ACCESS_KEY=FIXME

echo Discovering EC2 Environment

export VPC_ID=$(aws ec2 describe-vpcs | jq -r '.Vpcs[0].VpcId')
export VPC_SUBNETS=$(aws ec2 describe-subnets | jq -r ".Subnets[].SubnetId" | tr '\n' ' ')
export FIRST_VPC_SUB=$(aws ec2 describe-subnets | jq -r ".Subnets[0].SubnetId")

echo Generating Security Groups

export APP_SRV_SG_NAME=demo2AppServerSg
export APP_SRV_SG_ID=$(aws ec2 create-security-group --group-name $APP_SRV_SG_NAME --description "App Server" --vpc-id $VPC_ID | jq -r '.GroupId')

export DB_SG_NAME=demo2DbServerSg
export DB_SG_ID=$(aws ec2 create-security-group --group-name $DB_SG_NAME --description "Database" --vpc-id $VPC_ID | jq -r '.GroupId')

aws ec2 authorize-security-group-ingress --group-name $DB_SG_NAME --protocol tcp --port 3306 --source-group $APP_SRV_SG_ID

aws ec2 authorize-security-group-ingress --group-name $APP_SRV_SG_NAME --ip-protocol tcp --from-port 22 --to-port 22 --cidr-ip 0.0.0.0/0

echo Creating RDS Instance

export SUBNET_GROUP_NAME=demo2AllVpcSubnets
aws rds create-db-subnet-group --db-subnet-group-name $SUBNET_GROUP_NAME --db-subnet-group-description "All subnet groups" --subnet-ids $VPC_SUBNETS

export DB_NAME=demo2Database
export DB_MASTER_USER=master123
export DB_MASTER_PASS=mAsTeR321

aws rds create-db-instance --db-name $DB_NAME --db-instance-identifier $DB_NAME --allocated-storage 5 --db-instance-class db.t2.micro \
                           --engine mysql --master-username $DB_MASTER_USER --master-user-password $DB_MASTER_PASS \
                           --vpc-security-group-ids $DB_SG_ID --db-subnet-group-name $SUBNET_GROUP_NAME \
						   --multi-az

export DB_HOST=$(aws rds describe-db-instances --db-instance-identifier $DB_NAME | jq -r ".DBInstances[0].Endpoint.Address")
while [ $DB_HOST == "null" ] 
do
  sleep 10
  export DB_HOST=$(aws rds describe-db-instances --db-instance-identifier $DB_NAME | jq -r ".DBInstances[0].Endpoint.Address")
done

echo Uploading WAR to new S3 Bucket
# S3 public-read for simplicity - _most likely_ not feasible for production!

export DEPLOY_BUKET_NAME=cascloud2016install
export DEPLOY_BUCKET_LOCATION=eu-west-1

aws s3api create-bucket --create-bucket-configuration LocationConstraint=$DEPLOY_BUCKET_LOCATION --bucket $DEPLOY_BUKET_NAME

export WAR_FILE_LOCAL=target/demo-web-0.0.1-SNAPSHOT.war
export WAR_FILE_BUCKET=application.war

aws s3 cp $WAR_FILE_LOCAL s3://$DEPLOY_BUKET_NAME/$WAR_FILE_BUCKET --acl public-read

echo EC2 Instance Dependencies

export RSA_KEY_NAME=demo2ec2userkey
export RSA_KEY_FILE=demo2ec2userkey

ssh-keygen -N "" -t rsa -b 4096 -f $RSA_KEY_FILE
aws ec2 import-key-pair --public-key-material file://$RSA_KEY_FILE.pub --key-name $RSA_KEY_NAME

export AMAZON_LINUX_AMI=$(aws ec2 describe-images --owners amazon --filters "Name=description,Values=Amazon Linux AMI 2016.03.1 x86_64 HVM EBS" | jq -r ".Images[0].ImageId")

export CLOUD_INIT_FILE=cloudinit.sh
cat > ./$CLOUD_INIT_FILE <<DELIM
#!/bin/bash
wget https://s3-$DEPLOY_BUCKET_LOCATION.amazonaws.com/$DEPLOY_BUKET_NAME/$WAR_FILE_BUCKET
java -jar ./$WAR_FILE_BUCKET --server.port=80 --spring.datasource.url=jdbc:mysql://$DB_HOST:3306/$DB_NAME --spring.datasource.username=$DB_MASTER_USER --spring.datasource.password=$DB_MASTER_PASS &
DELIM

echo Discovering EC2 Environment II

export VPC_SUBNETS_COMMA=$(aws ec2 describe-subnets | jq -r ".Subnets[].SubnetId" | tr '\n' ',')

echo Generating Security Groups II

export LB_SG_NAME=demo2ElbSg
export LB_SG_ID=$(aws ec2 create-security-group --group-name $LB_SG_NAME --description "Internet facing Load Balancer" --vpc-id $VPC_ID | jq -r '.GroupId')

aws ec2 authorize-security-group-ingress --group-name $LB_SG_NAME --ip-protocol tcp --from-port 80 --to-port 80 --cidr-ip 0.0.0.0/0

aws ec2 authorize-security-group-ingress --group-name $APP_SRV_SG_NAME --protocol tcp --port 80 --source-group $LB_SG_ID

echo Creating Elastic Load Balancer

export LB_NAME=demo2Elb
export LB_DNS=$(aws elb create-load-balancer --load-balancer-name $LB_NAME --subnets $VPC_SUBNETS --security-groups $LB_SG_ID \
                                             --listeners "Protocol=http,LoadBalancerPort=80,InstanceProtocol=http,InstancePort=80" \
                                             | jq -r ".DNSName")

aws elb configure-health-check --load-balancer-name $LB_NAME \
 		                       --health-check "Target=HTTP:80/,Interval=30,Timeout=5,UnhealthyThreshold=8,HealthyThreshold=2"

aws elb modify-load-balancer-attributes --load-balancer-name $LB_NAME --load-balancer-attributes "{\"CrossZoneLoadBalancing\":{\"Enabled\":true}}"

echo Creating Auto Scaling Group

export LAUNCH_CONFIG_NAME=demo2LaunchConfig
aws autoscaling create-launch-configuration --launch-configuration-name $LAUNCH_CONFIG_NAME --image-id $AMAZON_LINUX_AMI \
                                            --key-name $RSA_KEY_NAME --security-groups $APP_SRV_SG_ID --user-data file://$CLOUD_INIT_FILE \
                                            --instance-type t2.micro --associate-public-ip-address

export AUTO_SCALING_GROUP_NAME=demo2AutoScaling
aws autoscaling create-auto-scaling-group --auto-scaling-group-name $AUTO_SCALING_GROUP_NAME --launch-configuration-name $LAUNCH_CONFIG_NAME \
                                          --min-size 1 --max-size 3 --desired-capacity 2 --load-balancer-names $LB_NAME \
                                          --health-check-type ELB --health-check-grace-period 60 --vpc-zone-identifier $VPC_SUBNETS_COMMA

echo Setup Reactive Auto Scaling

export UP_SCALE_POLICY_NAME=demo2ScaleUpPolicy
export UP_SCALE_POLICY_ARN=$(aws autoscaling put-scaling-policy --auto-scaling-group-name $AUTO_SCALING_GROUP_NAME --policy-name $UP_SCALE_POLICY_NAME \
                                                                --scaling-adjustment 1 --adjustment-type ChangeInCapacity --cooldown 70 \
                                                                | jq -r ".PolicyARN")

export DOWN_SCALE_POLICY_NAME=demo2ScaleDownPolicy
export DOWN_SCALE_POLICY_ARN=$(aws autoscaling put-scaling-policy --auto-scaling-group-name $AUTO_SCALING_GROUP_NAME --policy-name $DOWN_SCALE_POLICY_NAME \
                                                                  --scaling-adjustment -1 --adjustment-type ChangeInCapacity --cooldown 70 \
                                                                  | jq -r ".PolicyARN")

export HIGH_ALARM_NAME=demo2HighLatencyAlarm
aws cloudwatch put-metric-alarm --alarm-name $HIGH_ALARM_NAME --actions-enabled --alarm-actions $UP_SCALE_POLICY_ARN --metric-name Latency \
                                --namespace "AWS/ELB" --statistic "Average" --dimensions "Name=LoadBalancerName,Value=$LB_NAME" \
                                --period 60 --evaluation-periods 2 --threshold 0.3 --comparison-operator GreaterThanThreshold

export LOW_ALARM_NAME=demo2LowLatencyAlarm
aws cloudwatch put-metric-alarm --alarm-name $LOW_ALARM_NAME --actions-enabled --alarm-actions $DOWN_SCALE_POLICY_ARN --metric-name Latency \
                               --namespace "AWS/ELB" --statistic "Average" --dimensions "Name=LoadBalancerName,Value=$LB_NAME" \
                               --period 60 --evaluation-periods 2 --threshold 0.2 --comparison-operator LessThanThreshold

echo Try this in a few minutes:
echo curl -s http://$LB_DNS
