################################################################################
# Cuez Cloud - S3 Bucket for VM Import
################################################################################

resource "aws_s3_bucket" "vmimport" {
  bucket = "${var.project_name}-vmimport"

  tags = {
    Name = "${var.project_name}-vmimport"
    Role = "VM-Import"
  }
}

resource "aws_s3_bucket_public_access_block" "vmimport" {
  bucket = aws_s3_bucket.vmimport.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "vmimport" {
  bucket = aws_s3_bucket.vmimport.id

  rule {
    id     = "expire-old-vhds"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }
  }
}
