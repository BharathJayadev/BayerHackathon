terraform {
  backend "s3" {
    bucket = "hackathon123"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
