#!/bin/bash

shopt -s extglob

# printer is a convenience function to use the UTCS printers because I
# personally can't remember the commands. It also tries to protect you from
# printing docx files which always seems to be printed as junk bytes.
printer () {
    local num
    case $2 in
        +([0-9]))
            num=$2;;
        Plw+(0-9))
            # strip out the Plw string to store it as a number
            num=${$2:3};;
        *)
            >&2 echo "usage: printer [[print] [queue] [rm]] [0-9]+ [filename or job number]"
            return 1;;
    esac
    case $1 in
        print)
            if [ ! -f $3 ]
            then
                >&2 echo "usage: printer print ([0-9]+) (filename)"
                return 1
            fi
            if [[ $3 == *.docx ]]
            then
                read -p "Are you sure you want to print a docx file (may print out random bytes)? [yN] " yn
                if [[ $yn != [yY] ]]
                then
                    return
                fi
            fi
            lpr -Plw$num $3;;
        queue)
            lpq -Plw$num;;
        rm)
            local re='^[0-9]+$'
            if ! [[ $3 =~ $re ]]
            then
                >&2 echo "usage: printer rm ([0-9]+) (job number)"
                return 1
            fi
            lprm -Plw$num $3;;
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
        3)
            COMPREPLY=( $(compgen -f -- $cur) )
            ;;
    esac
}

complete -o filenames -F _printer printer
