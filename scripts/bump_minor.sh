#!/usr/bin/env bash
pushd . && cd src
  . .envrc
popd

# Get the last tag
tag=$(git tag -l | tail -n 1)
if [ -z "$tag" ]; then
  tag="0.0.0"
fi
echo "Last Tag: $tag"

# Generate build tag
newtag=v$(./scripts/semver.sh bump minor $(git tag -l | tail -n 1))
echo "New Tag: $newtag"

# Generate commit tag
commit=$(git log | head -n 3)

msg=$(echo "Last Commit: $commit")
echo "$msg" > .semver.commit.tag
echo "$newtag" > .semver.version.tag

cat .semver.version.tag
cat .semver.commit.tag
