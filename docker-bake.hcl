variable "REPO" {
  default = "lynsei"
}
variable "PROGRAM" {
  default = "gist-scan"
}
variable "BUILD" {
  default = "$BUILD"
}
variable "TAG" {
  default = "local"
}
target "package" {
  context = "."
  args = {
    buildno = "${BUILD}"
  }
  dockerfile = "Dockerfile.package"
  tags = ["${REPO}/${PROGRAM}:${TAG}"]
  no-cache = true
  platforms = ["linux/arm64","linux/amd64"]
}
