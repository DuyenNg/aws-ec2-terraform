data "template_file" "user_data" {
  template = "${file("kozo-ojt-terraform.tpl")}"
}

data "aws_route53_zone" "zone" {
  name = "${var.route53_hosted_zone_name}"
}