#!/bin/bash
#------------------------------------------------------------------------------#
## _set_colors ##
# Set Color codes to names
	_set_colors() {
		reset=$(echo -en '\033[0m')
		red=$(echo -en '\033[00;31m')
		green=$(echo -en '\033[00;32m')
		yellow=$(echo -en '\033[00;33m')
		blue=$(echo -en '\033[00;34m')
		magenta=$(echo -en '\033[00;35m')
		purple=$(echo -en '\033[00;35m')
		cyan=$(echo -en '\033[00;36m')
		lightgray=$(echo -en '\033[00;37m')
		lred=$(echo -en '\033[01;31m')
		lgreen=$(echo -en '\033[01;32m')
		lyellow=$(echo -en '\033[01;33m')
		lblue=$(echo -en '\033[01;34m')
		lmagenta=$(echo -en '\033[01;35m')
		lpurple=$(echo -en '\033[01;35m')
		lcyan=$(echo -en '\033[01;36m')
		white=$(echo -en '\033[01;37m')
	}
#------------------------------------------------------------------------------#
## _header ##
# Header text format function
		_header() {
			printf "\n${lcyan}==========  %s  ==========${reset}\n" "$@"
		}
#------------------------------------------------------------------------------#
## _select ##
# Selection text format function
		_select() {
			printf "${lgreen}%s${reset}\n" "$@"
		}
#------------------------------------------------------------------------------#
## _choose ##
# Selection text format function
		_choose() {
			printf "${lgreen}➜ %s${reset}\n" "$@"
		}

#------------------------------------------------------------------------------#
## _sep ##
# Seperator line format function
		_sep() {
			printf "\n${lpurple}========================================${reset}\n" "$@"
		}
#------------------------------------------------------------------------------#
## _success ##
# Successful text format function
		_success() {
			printf "${green}✔ %s${reset}\n" "$@"
		}
#------------------------------------------------------------------------------#
## _error ##
# Error text formatting function
		_error() {
			printf "${red}✖ %s${reset}\n" "$@"
		}
#------------------------------------------------------------------------------#
## _removed ##
# Removed text formtting function
		_removed() {
			printf "${green}✖ %s${reset}\n" "$@"
		}
#------------------------------------------------------------------------------#
## _warning ##
# Warning text formatting function
		_warning() {
			printf "${yellow}➜ %s${reset}\n" "$@"
		}
#------------------------------------------------------------------------------#
## _note ##
# Note text formatting function
		_note() {
			printf "${lyellow}Note:${reset}  ${lyellow}%s${reset}\n" "$@"
		}
#------------------------------------------------------------------------------#
## _ans_check ##
# Null responce check
	_ans_check() {
		while [ -z "${_ans}" ]; do
			_error "null string"
			_header "Re enter value"
			read _ans
		done
	}
#------------------------------------------------------------------------------#
## _system_os_arch_detect ##
# Get system OS and Arch
	_system_os_arch_detect() {
		sys_os=(`uname`)
		case $(uname -m) in
			armhf ) sys_arch="armv6l" ;;
			x86-64 ) sys_arch="x64" ;;
			i686 ) sys_arch="x86" ;;
			i386 ) sys_arch="x86" ;;
			* )	sys_arch="0" ;;
		esac
		_sep
		_success "Installed OS = ${sys_os}"
		_success "System Arch = ${sys_arch}"
		_sep
	}
#------------------------------------------------------------------------------#
## _all_caps ##
# convert to capitol letters
	_all_caps() {
		# Input str - Output str_caps
		str_caps=(`echo $str | awk '{print toupper($0)}'`)
	}
#------------------------------------------------------------------------------#
## _list_template ##
# List Template
	_list_template() {
	# Script wide listing function
	# Needs "_l0" array or other assigned for this to work
	# Sets selection value to "_list_output"
		counter=
		count=1
		c1=
		a=
		_header "${HEADING}"
		for c0 in "${_l0[@]}"
		do
			a0[$count]=$c0
			_select "$count ${a0[$count]}"
			((count++))
		done
		counter=${count}
		read c1
		_list_input_test		
		_list_test_loop
		_list_output=${a0[$c1]}
	}
#------------------------------------------------------------------------------#
## _list_test_loop ##
# Correct the selection input
	_list_test_loop() {
		while [ -z ${c1}  ] || [ ${c1} -gt ${counter} ]; do
			counter=
			count=1
			c1=
			a=
			_header "${HEADING}"
			for c0 in "${_l0[@]}"
			do
				a0[$count]=$c0
				_select "$count ${a0[$count]}"
				((count++))
			done
			counter=${count}
			read c1
			_list_input_test
		done
	}
#------------------------------------------------------------------------------#
## _list_test ##
# Test if input is a number
	_list_input_test() {
		#while [ -z ${c1}  ] || [ ${c1} -gt ${counter} ]; do
		case ${c1} in
			[1-9]*) _success "Entered - ${c1}";;
			*) 	c1= 
					_error "Bad Entry";;
		esac
	}
#------------------------------------------------------------------------------#
## _menu_test_loop ##
# Correct the selection input
	_menu_test_loop() {
		while [ -z ${c1}  ] || [ ${c1} -gt ${counter} ]; do
			counter=
			count=1
			c1=
			a=
			_sep
			_header "${HEADING}"
			_sep
			for c0 in "${l0[@]}"
			do
				a0[$count]=$c0
				_select "$count ${a0[$count]}"
				((count++))
			done
			counter=${count}
			read c1
			_list_input_test
		done
	}
#------------------------------------------------------------------------------#
## _menu_create_name
# Output menu item name to file
  _menu_create_name() {
      awk 'BEGIN {
        FS="\n"
        RS=""
        }
        {
          if ($1 == "_menu_include=1") {
            print$2
          }
        }' >> menu.conf
  }
#------------------------------------------------------------------------------#
## _menu_create_command
# Output menu command name to file
    _menu_create_command() {
      awk 'BEGIN {
        FS="\n"
        RS=""
        }
        {
          if ($1 == "_menu_include=1") {
            print$3
          }
        }' >> menu.conf
  }
#------------------------------------------------------------------------------#
## _menu_create
# Populates the Menu Arrays
  _menu_create() {
    echo "l0=(" >> menu.conf
    cat ${file_in} | _menu_create_name
    echo ")" >> menu.conf
    echo "opt0=(" >> menu.conf
    cat ${file_in} | _menu_create_command
    echo ")" >> menu.conf
  }
#------------------------------------------------------------------------------#
## _menu_list_template ##
# Menu List Function
	_menu_list_template() {
		a0=
		c1=
		count=1
		_sep
		_header "${HEADING}"
		_sep
		for c0 in "${l0[@]}"; do
			a0[$count]=$c0
			_select "$count - ${a0[$count]}"
			((count++))
		done
		counter=${count}
		read c1
		_list_input_test
		_menu_test_loop
		MENU_COUNT=${c1}
		MENU_OUTPUT=${a0[$c1]}
		opt_count=( `expr ${MENU_COUNT} - 1` )
	}
#------------------------------------------------------------------------------#
## _menu_command_run ##
# Command to run from menu command array
	_menu_command_run() {
		${opt0[$opt_count]}
	}
#------------------------------------------------------------------------------#
## _g_menu_fn ##
# Global Menu Function
	_g_menu_fn() {
		while :
		do
			# Generate menu list from menu list array
			_menu_list_template
			_sep
			# Run choosen command from menu command array
			_menu_command_run
		done
	}
#------------------------------------------------------------------------------#