provider "aws" {
  region="ap-south-1"
  profile="terauser"
} 

resource "aws_key_pair" "mansidaskey" {
  key_name   = "mansidas"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
}

resource "aws_security_group" "mansidas" {
  name        = "mansidas_security"
  description = "Allow http inbound traffic"
  vpc_id      = "vpc-c9f4e9a1"

  ingress {
    description = "http"
    from_port   = 0
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mansidas"
  }
}

resource "aws_instance" "task1" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "key_cc"
  security_groups=["mansidas_security"]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Dell/Downloads/key_cc")
    host     = aws_instance.task1.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }
  
  tags = {
    Name = "mansidas"
  }
}

resource "aws_ebs_volume" "mansidas" {
  availability_zone = aws_instance.task1.availability_zone
  size              = 1

  tags = {
    Name = "mansidas"
  }
}

resource "aws_s3_bucket" "mansidas" {
  bucket = "mansidas123"
  acl    = "public-read"

  tags = {
    Name        = "mansidas123"
  }
}

resource "aws_s3_bucket_object" "object" {
  bucket = "mansidas123"
  key    = "image_new"
  source = "bg6.jpg"
  acl = "public-read"
  
}

resource "aws_cloudfront_distribution" "mansidas" {
  origin {
    domain_name = "mansidas123.s3.amazonaws.com"
    origin_id   = "S3-mansidas123"
   }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "access-identity-mansidas123.s3.amazonaws.com"

  logging_config {
    include_cookies = false
    bucket          = "mansidas123.s3.amazonaws.com"
  }

  
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-mansidas123"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-mansidas123"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-mansidas123"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
      locations        = ["AL"]
    }
  }


  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


resource "aws_volume_attachment" "mansidas" {
 device_name = "/dev/sdf"
 volume_id = aws_ebs_volume.mansidas.id
 instance_id = aws_instance.task1.id
}

resource "null_resource" "nullremote"  {

depends_on = [
    aws_volume_attachment.mansidas,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Dell/Downloads/key_cc")
    host     = aws_instance.task1.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdf",
      "sudo mount  /dev/xvdf  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/mansidas19/cloudtask1.git /var/www/html/"
    ]
  }
}
