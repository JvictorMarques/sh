#!/usr/bin/env bash

function check_status {
    declare -r site="${1}"
    declare -r status_code=$(curl --output /dev/null --silent --head --write-out "%{http_code}" "${site}")
    if [[ "${status_code}" == "000" ]]; then
        printf "\x1b[38;5;196m [FALHA]\x1b[0m\t??? ${site}\n"
    else
        printf "\x1b[38;5;82m [OK]\x1b[0m\t${status_code} ${site}\n"
    fi
}
function validate_file {
    declare -r default_file="${1}"
    if [[ ! -f "${default_file}" ]]; then
        printf "\x1b[38;5;196m [ERRO]\x1b[0m Arquivo não existe: O arquivo '${default_file}' não foi encontrado no diretório atual.\n"
        exit 1
    elif [[ ! -s "${default_file}" ]]; then
        printf "\x1b[38;5;196m[ERRO]\x1b[0m Arquivo vazio: O arquivo '${default_file}' está vazio.\n"
        exit 1
    fi
}
function check_requirements {
    if ! command -v curl &>/dev/null; then
        printf "\x1b[38;5;196m [ERRO]\x1b[0m Requisito não satisfeito: Comando 'curl' não encontrado.\n"
        exit 1
    elif ! command -v nproc &>/dev/null; then
        printf "\x1b[38;5;196m [ERRO]\x1b[0m Requisito não satisfeito: Comando 'nproc' não encontrado.\n"
        exit 1
    fi
}
function run_checker {
    declare -i running_jobs=0
    declare -ir cores=$(($(nproc)))

    if [[ -t 0 ]]; then
        while [[ $# -gt 0 ]]; do
            check_status "$1" &
            ((running_jobs++))
            shift
            if [[ $running_jobs -gt $cores ]]; then
                wait
                running_jobs=0
            fi
        done
    else
        while IFS= read -r line || [ -n "${line}" ]; do
            check_status "${line}" &
            ((running_jobs++))
            if [[ $running_jobs -gt $cores ]]; then
                wait
                running_jobs=0
            fi
        done
    fi
    wait
}

function main {
    declare default_file="sites.txt"
    declare using_args=false
    declare -a args_list

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--file)
                shift
                default_file="${1}"
                ;;
            *)
                using_args=true
                args_list+=("${1}")
                shift
                ;;
        esac
    done
    if [[ -t 0 ]]; then
        if [[ "$using_args" == false ]]; then
            validate_file "${default_file}"
            run_checker < "${default_file}"
            exit
        fi
    fi
    run_checker "${args_list[@]}"
}

main "${@}"
