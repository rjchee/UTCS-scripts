#!/bin/bash

shopt -s extglob

# printer is a convenience function to use the UTCS printers because I
# personally can't remember the commands. It also tries to protect you from
# printing docx files which always seems to be printed as junk bytes.
printer () {
    local num
    case $2 in
        +([0-9]))
            num=$2
            ;;
        Plw+(0-9))
            # strip out the Plw string to store it as a number
            num=${$2:3}
            ;;
        *)
            >&2 echo "usage: printer [[print] [queue] [rm]] [0-9]+ [filename or job number]"
            return 1
            ;;
    esac
    case $1 in
        print)
            local files=("${@:3}")
            local foundDocx=false
            for file in "${files[@]}"
            do
                if [ ! -f "$file" ]
                then
                    >&2 echo "usage: printer print ([0-9]+) (filename)"
                    return 1
                fi
                if [[ "$file" == *.docx ]]
                then
                    foundDocx=true
                fi
            done
            if $foundDocx
            then
                read -p "Are you sure you want to print a docx file (may print out random bytes)? [yN] " yn
                if [[ $yn != [yY] ]]
                then
                    return
                fi
            fi
            for file in "${files[@]}"
            do
                lpr -Plw$num $file
            done
            ;;
        queue)
            lpq -Plw$num
            ;;
        rm)
            local args=("${@:3}")
            local user=$(whoami)
            if [ ${#args[@]} -eq 0 ]
            then
                # find all jobs owned by user and remove them
                args=( $(lpq -Plw$num | grep $user | sed -r 's|.*job ([0-9]*).*|\1|') )
            elif [ -f "$3" ]
            then
                local temp=()
                for file in "${args[@]}"
                do
                    # the printer lists files in a strange format, so just cut it
                    # down to the part without the file extension and hope it is
                    # found
                    file=$(echo $file | cut -d '.' -f 1)
                    # find the jobs printing the provided file and was sent by you,
                    # extract the job numbers from them
                    temp+=( "$(lpq -Plw$num | grep -B 1 "$file" | grep $user | sed -r 's|.*job ([0-9]*).*|\1|')" )
                done
                args=$temp
            else
                local re='^[0-9]+$'
                local temp=()
                for job in "${args[@]}"
                do
                    if ! [[ $job =~ $re ]]
                    then
                        >&2 echo "usage: printer rm ([0-9]+) [job number]"
                        return 1
                    fi
                    temp+=( "$job" )
                done
                args=$temp
            fi
            for arg in "${args[@]}"
            do
                lprm -Plw$num $arg
            done
            ;;
        *)
            >&2 echo "usage: printer [[print] [queue] [rm]] [0-9]+ [filename or job number]"
            return 1;;
    esac
}

_printer () {
    local cur=${COMP_WORDS[COMP_CWORD]}
    case $COMP_CWORD in
        1)
            COMPREPLY=( $(compgen -W "print queue rm" -- $cur) )
            ;;
        2)
            COMPREPLY=( $(compgen -W "301 303 Plw301 Plw303" -- $cur) )
            ;;
        *)
            local oldIFS="$IFS"
            IFS=$'\n'
            COMPREPLY=( $(compgen -f -- $cur) )
            IFS=$oldIFS
            ;;
    esac
}

complete -o filenames -F _printer printer
