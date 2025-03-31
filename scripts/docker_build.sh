#!/usr/bin/env bash
#!/usr/bin/env bash
set -u
set -e
do_build () { 
    cp $DENO_CERT .devcontainer/trusted_certs.pem
    docker buildx bake package && docker push lynsei/gist-sca:latest
    rm trusted_certs.pem
}

read -p "Confirm? (y/n) " -n 1 -r && [[ $REPLY =~ ^[Yy]$ ]] && do_build