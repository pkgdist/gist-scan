# Evaluate .env/.envcrypt files
$(touch .envcrypt; touch .env)
include .envcrypt
$(eval export $(shell sed -ne 's/ *#.*$$//; /./ s/=.*$$// p' .envcrypt))

# Print env var names and values
print-%: ##  Print env var names and values
	@echo $* = $($*)
echo-%: ##  Print any environment variable
	@echo $($*)

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## Print all commands and help info
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

env:  ## Source env file if you are running local
	./scripts/env.sh

build:  ## Check and Build the binaries
	deno check ./src/mod.ts
	deno compile --allow-all --no-check --target aarch64-apple-darwin --output ./bin/aarch64-apple-darwin/scanner ./src/mod.ts
	deno compile --allow-all --no-check --target x86_64-apple-darwin --output ./bin/x86_64-apple-darwin/scanner ./src/mod.ts

build-local:  ## Build the assets in a docker container
	docker buildx bake bin
	docker buildx bake release

git-head:  ## Get the latest git tag
	git tag -l | tail -n 1

bump-major:  ## Bump the major version tag
	./scripts/bump_major.sh

bump-minor:  ## Bump the minor version tag
	./scripts/bump_minor.sh

bump-patch:  ## Bump the patch version tag
	./scripts/bump_patch.sh

bump-build:  ## Bump the build version to a random build number
	./scripts/bump_build.sh



