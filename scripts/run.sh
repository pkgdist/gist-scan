set -u

# host
os=`uname -s`
rev=`uname -r`
arch=`uname -m`

# local
dir_home="/root" # parent image home is rootless
dir_fish="$dir_home/.config/fish" # parent image fish configuration
secret_gh=$(gh auth token)
docker_v=`docker version -f "{{.Server.Version}}"`
conf_location=`cat $PWD/.config.location`

# export
export __registry_org="lynsei"
export __img_name="$__registry_org/run.parent"
export __base_path=`basename $PWD`
export __platform="$arch"
export __yml_conf="$conf_location"
export __debug_mode=true

# check os info and apply rules
_os_local () {
    local os="unknown"
    # os specific logic can use this function in the future
    case "$(uname -s)" in
        Linux)
            # Linux users need docker
            os="Linux"
            ;;
        Darwin)
            # Mac users need docker
            os="Darwin"
            ;;
        CYGWIN*|MINGW*|MSYS*|MINGW32*|MINGW64*)
            # Windows users could be prompted about WSL if need be
            os="Windows"
            ;;
        FreeBSD)
            os="FreeBSD"
            ;;
        OpenBSD)
            os="OpenBSD"
            ;;
        NetBSD)
            os="NetBSD"
            ;;
        SunOS)
            os="SunOS"
            ;;
        AIX)
            os="AIX"
            ;;
        *)
        # Fallback check for unknown or custom OS
        os="unknown: $(uname -s)"
        ;;
    esac
    echo $os
}

# are we in a docker container or not
_in_container () { 
    if [ -f /proc/1/sched ]
        then # maybe host
            if [ ! $("cat /proc/1/sched | head -n 1 | grep init") ]
                then 
                echo 0 # definitely container
            else
                echo 1 # definitely host
            fi
        else
            echo 1
    fi
}

# is the docker command available or not
_is_docker () {
    reg=^[0-9]+\.[0-9]+\.[0-9]+ 
     [[ $docker_v =~ $reg ]] && echo "1"
}

# run a docker command as a one-off
_docker_run () {
    if [[ `_in_container` && `_is_docker` && `_os_local` =~ ^Darwin|Linux ]]
        then 

        _run=( 
            "docker run" 
            "--pull=always"
            "--privileged" 
            "--platform linux/$__platform"
            "-v $PWD/.cache.parent:/root/.cache.parent"
            "-v $PWD/.cache.child:/root/.cache.child"
            "-v $conf_location:/secrets/.config.yaml"
            "-v $PWD/.registry:/root/.registry"
            "-e __platform=$__platform"
            "-e __yml_conf=/secrets/.config.yaml"
            "-e __registry_org=$__registry_org"
            "-e __debug_mode=$__debug_mode"
            "--tmpfs /secrets:ro,noexec,nosuid,size=64k"
            "-it"
            "--rm" 
            "$_docker_opts" # options string
            "${__img_name}:${__platform}"
            "fish -c $__docker_cmd" # script
        )
        c=$(IFS=' '; echo "${_run[*]}")
            export _cmd=$c #  final cmd
            export _msg=''
        else
            export _cmd=''
            export _msg="In the container, use the .img CLI"
    fi
}

# run a docker shell interactively
_docker_shell() {
    if [[ `_in_container` && `_is_docker` && `_os_local` =~ ^Darwin|Linux ]]
        then
        _shell=(
            "docker run"  
            "--pull=always"
            "--privileged" 
            "--platform linux/$__platform"
            "-v $PWD/.cache.parent:/root/.cache.parent"
            "-v $PWD/.cache.child:/root/.cache.child"
            "-v $conf_location:/secrets/.config.yaml"
            "-v $PWD/.registry:/root/.registry"
            "-e __platform=$__platform"
            "-e __yml_conf=$__yml_conf"
            "-e __registry_org=$__registry_org"
            "-e __debug_mode=$__debug_mode"
            "--tmpfs /secrets:ro,noexec,nosuid,size=64k"
            "-it"
            "--rm" 
            "$_docker_opts" # options string
            "${__img_name}:${__platform}"
            "fish -i" # no script
        )
        c=$(IFS=' '; echo "${_shell[*]}")
            export _cmd=$c #  final cmd
            export _msg=''
        else
            export _cmd=''
            export _msg="In the container use .img CLI"
    fi
}

# export all functions
export -f _docker_run
export -f _docker_shell
export -f _os_local
export -f _in_container
export -f _is_docker

        _help=(
            "   .run   Run Nested DevOps containes as a CLI"
            " v${_version} "
            ""
            "          Usage:  -r                   run command and exit"
            "                  -s                   *or* run shell interactively"
            ""
            "           Options:"
            "                   --                  <parent container command or function>"
            "                   -o                  docker options: i.e.-  --rm or -w"
            "                   -h                  pass -h for this help"
            "                   -d                  debug output of docker command"
            ""  
            ""
            "           Examples:"
            ""  
            "              .run -s                        # shell into parent container"
            ""  
            "              .run -r  -- '.run volta; \     # run parent with a volta child container"
            "                      .run npx yo '          # run command 'npx yo' in child contain4r"
            "                                             # into the host director local mount: $PWD/cache"
            ""  
            "              # shell into parent container and mount config to host"
            "" 
            "              .run -s -o '-w /app'  # force working directory in shell"
            ""
        )

# no arguments supplied
if [ $# -eq 0 ]
then 
    echo "Type -h|--help for program help."
fi

    while getopts ":o:drsh" opt; do
    case $opt in
        o)
            export _docker_opts="$OPTARG"
        ;;
        d)
            flag_d=true
        ;;
        r)
            flag_r=true
        ;;
        s)
            flag_s=true
        ;;
        h)
            printf "%s\n" "${_help[@]}"
        ;;
        \?)
           echo "Invalid option: -$OPTARG" >&2
            exit 1
        ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
    esac
    done

    shift $((OPTIND-1)) # shift options off 
    export __docker_cmd="$@" # produce arguments beyond --

    [[ ! -z $__docker_cmd && ! $flag_s ]] && _docker_run  # docker run checks anything passed after "--" 

    [[ $flag_r ]] && _docker_run          # docker run
    [[ $flag_s ]] && _docker_shell        # docker interactive


    [[ ! -z $flag_d ]] && echo "Arguments: $@ "         # debug
    [[ ! -z $flag_d ]] && echo -e "Docker command: \n\n $_cmd"  # debug

    `echo $_cmd`
