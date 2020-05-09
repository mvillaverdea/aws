data "aws_iam_policy" "AmazonS3FullAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app_iam_role" {
  name               = "APP-IAM-ROLE"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_instance_profile" "app_instance_profile" {
  role = aws_iam_role.app_iam_role.name
  name = "APP-INSTANCE-PROFILE"
}

resource "aws_iam_role_policy_attachment" "app_s3_policy_attachment" {
  policy_arn = data.aws_iam_policy.AmazonS3FullAccess.arn
  role       = aws_iam_role.app_iam_role.name
}

resource "aws_iam_role" "spark_cluster_iam_emr_service_role" 	{
name = "spark_cluster_emr_service_role"
assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "emr-service-policy-attach" {
  role = "{aws_iam_role.spark_cluster_iam_emr_service_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

resource "aws_iam_role" "spark_cluster_iam_emr_profile_role" {
  name = "spark_cluster_emr_profile_role"
  #assume_role_policy = <<EOF
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "profile-policy-attach" {
   role = "{aws_iam_role.spark_cluster_iam_emr_profile_role.id}"
   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

resource "aws_iam_instance_profile" "emr_profile" {
   name = "spark_cluster_emr_profile"
   role = "{aws_iam_role.spark_cluster_iam_emr_profile_role.name}"
}