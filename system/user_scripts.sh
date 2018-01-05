#!/bin/bash
#------------------------------------------------------------------------------#
## _system_user_create ##
# System user create - Input ${_user_name} variable
    _system_user_create() {
        _header "Creating user - ${_user_name}"
        _note "This is a system account with no home folder or password"
        sudo useradd -M --system ${_user_name}
        _system_user_check
        case ${_user_status} in
            0) _success "${_user_name} created" ;;
            1) _warning "${_user_name} not created";;
        esac
    }
#------------------------------------------------------------------------------#
## _user_create ##
# System user create - Input ${_user_name} variable
    _user_create() {
        _header "Creating user - ${_user_name}"
        _note "This is a system account with no home folder or password"
        sudo useradd  ${_user_name}
        _system_user_check
        case ${_user_status} in
            0) _success "${_user_name} created" ;;
            1) _warning "${_user_name} not created";;
        esac
    }
#------------------------------------------------------------------------------#