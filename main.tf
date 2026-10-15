resource "aws_security_group" "ec2instance"{
    name = "groupwilluseforect"
    description = "willuseforec2"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol ="0"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "docker" {
    ami = "youramiID"
    instance_type = "t3.micro"

    vpc_security_group_ids = [aws_security_group.ec2instance.id]

    iam_instance_profile = aws_iam_instance_profile.profileforec2.name

    depends_on = [aws_iam_role_policy.ec2-s3-policy]

    tags = {
        Name = "dockerinstance"
        Description = "it_has_s3_access"
    }
}

resource "aws_s3_bucket" "tests3" {
    bucket_prefix = "s3-bucket-docker"

    tags = {
        Name = "s3-private-bucket"
    }
}

resource "aws_s3_bucket_public_access_block" "publich_block" {
        bucket = aws_s3_bucket.tests3.id

        block_public_acls = true
        block_public_policy = true
        ignore_public_acls = true
        restrict_public_buckets = true

}

resource "aws_iam_role" "access-ec2-s3" {
    name = "ec2-access-s3"
    description = "this will provide access to ec2 and s3"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
            Statement = [{         
                
            Effect = "Allow"

            Principal = {
                Service = "ec2.amazonaws.com"
            }
        Action = "sts:AssumeRole"
}]
})
    
    }

resource "aws_iam_role_policy" "ec2-s3-policy" {
        name = "ec2-fullaccess-s3"
        role = aws_iam_role.access-ec2-s3.id

        policy = jsonencode({
            Version = "2012-10-17"

            Statement = [
           { Effect = "Allow"

            Action = ["s3:ListBucket"]

            Resource = aws_s3_bucket.tests3.arn
        }, {

            Effect = "Allow"

            Action = ["s3:GetObject",
                       "s3:PutObject"]
            
            Resource = "${aws_s3_bucket.tests3.arn}/*"
            }
        ]

    })
}


resource "aws_iam_instance_profile" "profileforec2" {
            name = "profileforec2"
            role = aws_iam_role.access-ec2-s3.name
    }