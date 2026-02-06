################################################################################
# Cuez Cloud - IAM Role for VM Import
################################################################################

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "vmimport" {
  name = "vmimport"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vmie.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "vmimport"
          }
        }
      }
    ]
  })

  tags = {
    Name = "vmimport"
    Role = "VM-Import"
  }
}

resource "aws_iam_role_policy" "vmimport_s3" {
  name = "vmimport-s3-access"
  role = aws_iam_role.vmimport.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetBucketAcl"
        ]
        Resource = [
          aws_s3_bucket.vmimport.arn,
          "${aws_s3_bucket.vmimport.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "vmimport_ec2" {
  name = "vmimport-ec2-access"
  role = aws_iam_role.vmimport.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:ModifySnapshotAttribute",
          "ec2:CopySnapshot",
          "ec2:RegisterImage",
          "ec2:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}
