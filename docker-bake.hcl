variable "REPO" {
  default = "lynsei"
}
variable "PROGRAM" {
  default = "new-program"
}
variable "BUILD" {
  default = "$BUILD"
}

target "bin" {
  context = "."
  args = {
    buildno = "${BUILD}"
  }
  dockerfile = "Dockerfile.package"
  tags = ["${REPO}/${PROGRAM}:${TAG}"]
  no-cache = true
  platforms = ["linux/arm64","linux/amd64"]
}

target "release" {
  context = "."
  args = {
    buildno = "${LYNS_INSTALL_BUILD_NUM}"
  }
  dockerfile = "Dockerfile.release"
  tags = ["${REPO}/${PROGRAM}.release:${TAG}"]
  no-cache = true
  platforms = ["linux/arm64","linux/amd64"]
}
