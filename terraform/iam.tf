resource "aws_iam_role" "v2_ec2" {
  name                 = "v2-ec2-role"
  description          = "Allows EC2 instances to call AWS services on your behalf."
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = "aws-prod-lab"
    Version = "V2"
  }
}

resource "aws_iam_role_policy_attachment" "v2_ec2_ssm" {
  role       = aws_iam_role.v2_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "v2_ec2_cloudwatch" {
  role       = aws_iam_role.v2_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "v2_s3_bucket_access" {
  name = "v2-s3-bucket-access"
  role = aws_iam_role.v2_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = [
          aws_s3_bucket.project.arn
        ]
      },

      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]

        Resource = [
          "${aws_s3_bucket.project.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "v4_rds_secret_access" {
  name = "v4-rds-secret-access"
  role = aws_iam_role.v2_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadV4RDSSecret"
        Effect = "Allow"
        Action = "secretsmanager:GetSecretValue"

        Resource = aws_db_instance.v4.master_user_secret[0].secret_arn
      },

      {
        Sid      = "DecryptV4RDSSecret"
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = aws_kms_key.v4.arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "v2_ec2" {
  name = "v2-ec2-role"
  role = aws_iam_role.v2_ec2.name
}