provider "aws" {
region  = "us-east-2"
}
# access_key = var.access_key
# secret_key = var.secret_key
# }
#1.create an ec2 instance
resource "aws_instance""my-first-server"{
ami="ami-0e82959d4ed12de3f"
instance_type="t2.micro"
tags={
     Name="web-server"
   }

}

#2. Create an S3 bucket
resource "aws_s3_bucket" "b" {
  bucket = "insightdemobucketdeployment"
  acl    = "private"

  tags = {
    Name        = "Myonlybucket"
    Environment = "Dev"
  }
}

#3.Create a folder into S3
resource "aws_s3_bucket_object" "folder1" {
    bucket = aws_s3_bucket.b.bucket
    acl    = "private"
    key = "new_object_lambda_key"
    source = "./root/s3_trigger-1.0.0.jar"
    etag = "${md5(filebase64sha256("./root/s3_trigger-1.0.0.jar"))}"
}

#4. Uploading jar file to lambda by creating lambda functions
resource "aws_lambda_function" "lambda-sample" {
  function_name="lambda_test_sample_deploy"
  s3_bucket=aws_s3_bucket.b.bucket
  s3_key=aws_s3_bucket_object.folder1.key
  handler="com.test.App::handleRequest"
  runtime="java8"

  role="${aws_iam_role.lambda_exec.arn}"
  //policy="${file("./root/iam-policy.json")}"
}

#5.IAM Role that dictates what other AWS services lambda
resource "aws_iam_role" "lambda_exec"{
  name="example_lambda"
  assume_role_policy ="${file("./root/iam-policy.json")}"
  # aws_assume_policy = <<- EOF
# {
# #     "Version":"2012-10-17",
# #     "Statement":[
# #       {
# #         "Action":"sts:AssumeRole",
# #         "Principal":{
# #           "Service":"lambda.awsamazon.com"
# #         },
# #         "Effect":"Allow",
# #          "Sid":""
# #          }
# #         ]
# #   }
# # EOF
}
#6.give permissions for lambda to access triggers
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-sample.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.b.arn
}

#7. Add s3 trigger
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.b.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda-sample.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "AWSLogs/"
    filter_suffix       = ".log"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

#8.Give permission to Lambda to view cloudwatch while triggers
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-sample.function_name
  principal     = "events.amazonaws.com"
  source_arn    = "arn:aws:events:eu-east-2:111122223333:rule/RunDaily"
  qualifier     = aws_lambda_alias.test_alias.name
}

resource "aws_lambda_alias" "test_alias" {
  name             = "testalias"
  description      = "a sample description"
  function_name    = aws_lambda_function.lambda-sample.function_name
  function_version = "$LATEST"
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/${aws_lambda_function.lambda-sample.function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "lambda_logging" {
  name = "lambda_logging"
  path = "/"
  description = "IAM policy for logging from a lambda"

  policy = "${file("./root/iam-lambda-logging.json")}"
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = "${aws_iam_role.lambda_exec.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}

#9.Upload a file into S3 bucket to create trigger
resource "aws_s3_bucket_object" "file_upload" {
  bucket = aws_s3_bucket.b.bucket
  key    = "my_resume"
  source = "./root/Resume_Srinivasa.pdf"
  etag   = "${md5(filebase64sha256("./root/Resume_Srinivasa.pdf"))}"
}

# #1.create a VPC
# resource "aws_vpc" "insightDevopsVPC" {
#   cidr_block = "10.0.0.0/16"
#   tags={
#     Name:"InsightVPC"
#   }
# }
# # 2.Create Internet Gateway
# resource "aws_internet_gateway" "gw" {
#   vpc_id = aws_vpc.insightDevopsVPC.id
# }
# # 3.Create Customer route table
# resource "aws_route_table" "prod-route-table" {
#   vpc_id = aws_vpc.insightDevopsVPC.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.gw.id
#   }

#   route {
#     ipv6_cidr_block        = "::/0"
#     gateway_id = aws_internet_gateway.gw.id
#   }

#   tags = {
#     Name = "Prod"
#   }
# }
# # 4.Create a subnet
# resource "aws_subnet" "subnet-1" {
#   vpc_id     = aws_vpc.insightDevopsVPC.id
#   cidr_block = "10.0.1.0/24"
#   availability_zone = "us-east-2"
#   tags={
#     Name="prod-subnet"
#   }
# }
# # 5.Associate subnet with route table
# resource "aws_route_table_association" "a" {
#   subnet_id      = aws_subnet.subnet-1.id
#   route_table_id = aws_route_table.prod-route-table.id
# }
# # 6.Create security group to allow 22,80,443
# resource "aws_security_group" "allow_web" {
#   name        = "allow_web_traffic"
#   description = "Allow web traffic"
#   vpc_id      = aws_vpc.insightDevopsVPC.id

#   ingress {
#     description = "HTTPS"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     description = "HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     description = "SSH"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "allow_web"
#   }
# }
# # 7.Create a network interface with an ip in the subnet that was created in the step 4
# resource "aws_network_interface" "webserver-raghav" {
#   subnet_id       = aws_subnet.subnet-1.id
#   private_ips     = ["10.0.1.50"]
#   security_groups = [aws_security_group.allow_web.id]
# }
# # 8.Assign an elastic IP to the network interface created in step 7

# resource "aws_eip" "one" {
#   vpc                       = true
#   network_interface         = aws_network_interface.webserver-raghav.id
#   associate_with_private_ip = "10.0.1.50"
#   depends_on                = [aws_internet_gateway.gw]
# }
# # 9.Create ubuntu server and install enable apache2
# resource "aws_instance""web-server-instance"{
#   ami="ami-06b263d6ceff0b3dd"
#   instance_type="t2.micro"
#   availability_zone="us-east-1a"
#   key_name="myTerraformKey"

#   network_interface {
#     device_index=0
#     network_interface_id = aws_network_interface.webserver-raghav.id
#   }
#   user_data = <<-EOF
#               #!/bin/bash
#               sudo apt update -y
#               sudo apt install apache2-y
#               sudo systemctl start apache2
#               sudo bash -c 'echo your very first web server >/var/www/htm/index.html'
#               EOF
#   tags={
#     Name="web-server"
#   }

# }