resource "aws_security_group" "rds" {
  name   = "rds-${var.identifier}"
  vpc_id = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(var.tags, map("Name", format("rds-%s", var.identifier)))}"
}

resource "aws_rds_cluster" "default" {
  apply_immediately            = "${var.apply_immediately}"
  availability_zones           = "${var.availability_zones}"
  backup_retention_period      = "${var.backup_retention_period_in_days}"
  cluster_identifier           = "${var.identifier}"
  count                        = "${lookup(map("0", "0"), var.aurora_instance_count, 1)}"
  database_name                = "${var.db_name}"
  db_subnet_group_name         = "${aws_db_subnet_group.rds.0.id}"
  deletion_protection          = "${var.deletion_protection}"
  master_password              = "${var.db_password}"
  master_username              = "${var.db_username}"
  port                         = "${var.db_port}"
  preferred_backup_window      = "${var.backup_window}"
  preferred_maintenance_window = "${var.maintenance_window}"
  snapshot_identifier          = "${var.snapshot_identifier}"
  tags                         = "${var.tags}"
  vpc_security_group_ids       = ["${aws_security_group.rds.id}"]
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  cluster_identifier    = "${aws_rds_cluster.default.0.id}"
  copy_tags_to_snapshot = "${var.copy_tags_to_snapshot}"
  count                 = "${var.aurora_instance_count}"
  db_subnet_group_name  = "${aws_db_subnet_group.rds.0.id}"
  identifier            = "${var.identifier}-${count.index}"
  instance_class        = "${var.instance_class}"
  publicly_accessible   = "${var.publicly_accessible}"
  skip_final_snapshot   = "${var.skip_final_snapshot}"
  tags                  = "${var.tags}"
}

resource "aws_db_instance" "default" {
  allocated_storage            = "${var.rds_storage}"
  allow_major_version_upgrade  = "${var.rds_allow_major_version_upgrade}"
  apply_immediately            = "${var.apply_immediately}"
  backup_retention_period      = "${var.backup_retention_period_in_days}"
  backup_window                = "${var.backup_window}"
  copy_tags_to_snapshot        = "${var.copy_tags_to_snapshot}"
  count                        = "${var.rds_instance_count}"
  db_subnet_group_name         = "${join("", aws_db_subnet_group.rds.*.name)}"
  deletion_protection          = "${var.deletion_protection}"
  engine                       = "${var.rds_engine}"
  engine_version               = "${var.rds_version}"
  identifier                   = "${var.identifier}"
  instance_class               = "${var.instance_class}"
  iops                         = "${var.iops}"
  maintenance_window           = "${var.maintenance_window}"
  multi_az                     = "${var.rds_multi_az}"
  name                         = "${var.db_name}"
  parameter_group_name         = "${var.parameter_group_name}"
  password                     = "${var.db_password}"
  port                         = "${var.db_port}"
  publicly_accessible          = "${var.publicly_accessible}"
  replicate_source_db          = "${var.replicate_source_db}"
  skip_final_snapshot          = "${var.skip_final_snapshot}"
  snapshot_identifier          = "${var.snapshot_identifier}"
  storage_type                 = "${var.rds_storage_type}"
  tags                         = "${var.tags}"
  username                     = "${var.db_username}"
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  vpc_security_group_ids       = ["${aws_security_group.rds.id}"]
  storage_encrypted            = "true"
}

resource "aws_db_subnet_group" "rds" {
  count      = "${var.replicate_source_db == "" ? 1 : 0}"
  name       = "${var.identifier}"
  subnet_ids = ["${var.subnet_ids}"]
  tags       = "${var.tags}"
}
