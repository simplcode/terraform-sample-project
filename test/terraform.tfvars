env = "test"
region = "us-east-2"
domain = "xxservice.com"
/*
AWS Elastic Beanstalk Route 53 hosting zone ID
https://docs.aws.amazon.com/ko_kr/general/latest/gr/rande.html#elasticbeanstalk_region

N.Virginia: Z117KPS5GTRQ2G
Ohio: Z14LCN19Q5QHIC
Tokyo: Z1R25G3KIG2GBW
Seoul: Z3JE5OI70TWKCP
*/
elasticbeanstalk-zone-id = "Z14LCN19Q5QHIC"

elasticbeanstalk-java8 = "64bit Amazon Linux 2018.03 v2.8.3 running Java 8"

elasticbeanstalk-tomcat = "64bit Amazon Linux 2018.03 v3.1.3 running Tomcat 8.5 Java 8"

name-prefix = "XXSVC"

tags = {
  "Company" = "XXService",
  "Alias" = "XXSVC",
  "ManagedBy" = "Terraform"
}

vpc-cidr = "10.3.0.0/16"

publicA-cidr = "10.3.0.0/20"

publicA-subnets = [
  "10.3.0.0/22",
  "10.3.4.0/22",
  "10.3.8.0/22",
  "10.3.12.0/22"
]

publicB-cidr = "10.3.16.0/20"

publicB-subnets = [
  "10.3.16.0/22",
  "10.3.20.0/22",
  "10.3.24.0/22",
  "10.3.28.0/22"
]

privateA-cidr ="10.3.64.0/18"

privateA-subnets = [
  "10.3.64.0/20",
  "10.3.80.0/20",
  "10.3.96.0/20",
  "10.3.112.0/20"
]

privateB-cidr ="10.3.128.0/18"

privateB-subnets = [
  "10.3.128.0/20",
  "10.3.144.0/20",
  "10.3.168.0/20",
  "10.3.176.0/20"
]

/*
59.59.29.29: Admin
*/
inbound-cidrs = [
  "59.59.29.0/24"
]

/*
List of XX servers
35.35.25.25 : erp
45.45.25.25 : api
*/
internal-service-cidrs = [
  "35.35.25.25/32",
  "45.45.25.25/32"
]

ssh-key = "aws-ohio-xxsvc"

eb-ec2-key = "aws-ohio-xxsvc-eb"