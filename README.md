# aws-xxservice
Terraform Project for xxservice
>- Terraform v.09.x
>- Terraform Registry가 서비스 되기 전 작성된 프로젝트로 사용된 모듈들은 직접 작성함.
>- 코드에 사용된 domain, secret등은 익명화.
>- Packer, Github action, Terraform cloud 등을 사용하지 않는 코드(참고용).

### Domain
- Root domain: xxservice.com 
- 2nd: 개별 서비스 
- 3rd: 서비스타입(api, webhook, etc.)

### Region
| Environment        | Region | Description |
| ------------------ | ------ | ----------- |
| Test               | us-east-2(Ohio) |             |
| Production-us-east | us-east-1(N.Virginia) |             |

## Network
VPC CIDR: 10.3.0.0/16  
NAT per each public subnet 

### Subnets
- PublicA Group: Default subnet group for internet facing services (ie. nginx, ssh bastion, ELB, etc.)
  - CIDR: 10.3.0.0/20 (4094 hosts)
- PublicB Group: Internet facing services with limited access (ie. api for internal services)
  - CIDR: 10.3.16.0/20
- Reserved public CIDR for future: 10.3.32.0/19
- PrivateA Group: Applications (ie. Elasticbeanstalk, Docker, EC2, etc.)
  - CIDR: 10.3.64.0/18 (16382 hosts)
- PrivateB Group: Databases
  - CIDR: 10.3.128.0/18
- Reserved private CIDR for future: 10.3.192.0/18

| Name      | AZ    | CIDRs          |
| --------- | ----- | -------------- |
| PublicA0  | zone1 | 10.3.0.0/22    |
| PublicA1  | zone2 | 10.3.4.0/22    |
| PublicA2  | zone3 | 10.3.8.0/22    |
| PublicA3  | zone4 | 10.3.12.0/22   |
| PublicB0  | zone1 | 10.3.16.0/22   |
| PublicB1  | zone2 | 10.3.20.0/22   |
| PublicB2  | zone3 | 10.3.24.0/22   |
| PublicB3  | zone4 | 10.3.28.0/22   |
| --------- | ----- | -------------  |
| PrivateA0 | zone1 | 10.3.64.0/20   |
| PrivateA1 | zone2 | 10.3.80.0/20   |
| PrivateA2 | zone3 | 10.3.96.0/20   |
| PrivateA3 | zone4 | 10.3.112.0/20  |
| PrivateB0 | zone1 | 10.3.128.0/20  |
| PrivateB1 | zone2 | 10.3.144.0/20  |
| PrivateB2 | zone3 | 10.3.160.0/20  |
| PrivateB3 | zone4 | 10.3.176.0/20  |

## Projects 
| Name                    | Module       |
| ----------------------- | ------------ |
| ERP                     | ERP          | 
| Core                    | Core         |
| API                     | API          |
