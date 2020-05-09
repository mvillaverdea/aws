provider "aws" {
  region = var.aws_region
}

# terraform {
#   backend "s3" {
#     bucket = "COURSE-TFSTATES"
#     key    = "infra-cm-instructors/terraform.tfstate"
#     region = "${var.aws_region}"
#   }
# }

terraform {
  backend "local" {
    path = "terraform.tfstate"
    bucket = "terraform-bucket-name"
  }
}

resource "aws_emr_cluster" "emr-spark-cluster" {
name = "EMR-cluster-example"
release_label = "emr-5.9.0"
applications = ["Ganglia", "Spark", "Zeppelin", "Hive", "Hue"]
 
ec2_attributes {
  instance_profile = "{aws_iam_instance_profile.emr_profile.arn}"
  key_name = "{aws_key_pair.emr_key_pair.key_name}"
  subnet_id = "{aws_vpc.COURSE_VPC.id}"
  emr_managed_master_security_group = "{aws_security_group.master_security_group.id}"
  emr_managed_slave_security_group = "{aws_security_group.slave_security_group.id}"
}
 
master_instance_group {
    instance_type = "m3.xlarge"
}

core_instance_group {
    instance_type = "m2.xlarge"
    instance_count = 2
}

log_uri = "{aws_s3_bucket.logging_bucket.uri}"

tags = merge(
    {
     "Name" = "EMR-cluster"
     "role" = "EMR_DefaultRole"
    },
    local.default_tags,
)
  service_role = "{aws_iam_role.spark_cluster_iam_emr_service_role.arn}"
}

resource "aws_emr_instance_group" "task_group" {
    cluster_id = "{aws_emr_cluster.emr-spark-cluster.id}"
    instance_count = 4
    instance_type = "m3.xlarge"
    name = "instance_group"
}