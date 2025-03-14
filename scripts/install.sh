#!/bin/bash

# We don't need return codes for "$(command)", only stdout is needed.
# Allow `[[ -n "$(command)" ]]`, `func "$(command)"`, pipes, etc.
# shellcheck disable=SC2312

set -u

abort() {
  printf "%s\n" "$@" >&2
  exit 1
}

# Fail fast with a concise message when not using bash
# Single brackets are needed here for POSIX compatibility
# shellcheck disable=SC2292
if [ -z "${BASH_VERSION:-}" ]
then
  abort "Bash is required to interpret this script."
fi

# Check if script is run with force-interactive mode in CI
if [[ -n "${CI-}" && -n "${INTERACTIVE-}" ]]
then
  abort "Cannot run force-interactive mode in CI."
fi

# Check if both `INTERACTIVE` and `NONINTERACTIVE` are set
# Always use single-quoted strings with `exp` expressions
# shellcheck disable=SC2016
if [[ -n "${INTERACTIVE-}" && -n "${NONINTERACTIVE-}" ]]
then
  abort 'Both `$INTERACTIVE` and `$NONINTERACTIVE` are set. Please unset at least one variable and try again.'
fi

# Check if script is run in POSIX mode
if [[ -n "${POSIXLY_CORRECT+1}" ]]
then
  abort 'Bash must not run in POSIX mode. Please unset POSIXLY_CORRECT and try again.'
fi

export __base_path=`basename $PWD`

pushd . && cd $PWD/scripts 
	export PATH="$PATH:$PWD" && echo -e "\n\n\nPATH: \n\n $PATH" 
  
  # always pull new .run
	curl -fsSL https://gist.githubusercontent.com/lynsei/116fd036050b50aa8d7e0c2faf8e3cc4/raw/8cc32645eaee0b83be49f334f898f2d107f0f788/run.sh -o $PWD/.run
popd

# install brew if it does not exist
if [[ `which brew` ]]
	then
  	echo "Brew detected!"
  else
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o $PWD/install.sh
    chmod +x $PWD/install.sh
    bash -c "NONINTERACTIVE=true $PWD/install.sh"
fi

# add path to fish if it exists otherwise install it
if [[ `which fish` ]]
	then 
    echo "Fish detected! Adding to your config.fish"
		echo  "fish_add_path -ag $PWD/scripts" >> ~/.config/fish/config.fish
else
	echo "Fish not detected, installing..."
  brew reinstall fish
fi

echo -e "\nAdded $PWD/scripts to your PATH. \n\n"
echo -e "This application is easily configured using YAML.\n"
echo "Do you want to output an example configuration file?"
read -r -p "[y/n] " response

YML_CONFIG=$(cat <<-END
secrets:
  storage: 
    command:
      - "gh auth token"
    files: 
      - "/secrets/.tokens/secrets.sh"
mounts:
  bind:
    - "$PWD/.cache:/root/devops"
    - "$PWD/.config:/root/.config"
tokens:
  az:
    - ""
  jfrog:
    - ""
  github:
    - ""
END
)

case "$response" in
    [yY][eE][sS]|[yY]) 

        def_path="$PWD/.config.yaml"
        echo "Default Path:  $PWD/.config.yaml"
        read -r -p "[leave blank for default]" fn_response
        fn_response=${fn_response:-$def_path}
        echo "Output to: $fn_response"
        

        if [[ $def_path != $fn_response ]]; then
            echo "$YML_CONFIG" > $fn_response
            echo "$fn_response" > $PWD/.config.location
          else
            echo "$YML_CONFIG" > $def_path
            echo "$def_path" > $PWD/.config.location
        fi

        ;;
    *)
        echo "File has not been created."
        ;;
esac


echo -e "\n\n\nStore Docker Credentials?"
echo "(requires docker)"
read -r -p "[y/n] " response2

case "$response2" in
    [yY][eE][sS]|[yY]) 
        rm -rf $PWD/.registry # adding credentials removes existing ones
        mkdir -p $PWD/.registry # recreate .registry
        export __saltstring=`date '+%Y-%m-%d %H:%M:%S' | sha1sum | rev | cut -c2- | rev`
        echo "$__saltstring" > $PWD/.registry/.env.salt
        echo -e "\nWrote salt.\n\n"

        echo "Type your docker registry URL here:"
        read -p "Enter registry: " registry
        echo "$registry" > $PWD/.registry/.env.docker.registry

        echo "Type your docker username here:"
        read -p "Enter user: " username
        echo "$username" > $PWD/.registry/.env.docker.user

        echo "Type your docker password here (storage is encrypted):"
        read -s -p "Enter password: " password

        echo "$password" > $PWD/.registry/.tmppass
        docker run -it --rm --platform linux/`uname -m` -v $PWD/.registry:/tmp lynsei/run.child.openssl:`uname -m` enc -e -aes-256-cbc -pbkdf2 -iter 1000000 -nosalt -base64 -in /tmp/.tmppass -k pass:"$__saltstring" -out /tmp/.encrypted
 
            rm $PWD/.registry/.tmppass
            mv $PWD/.registry/.encrypted $PWD/.registry/.env.docker.pass.encrypted

        ;;
    *)
        echo "Credentials not stored."
        ;;
esac


echo "$USAGE"

