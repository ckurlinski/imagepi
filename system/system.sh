#!/bin/bash
#------------------------------------------------------------------------------#
## _dpkg_check ##
# Check to see if package is install - Input variable _dpkg
	_dpkg_check() {
		if [[ $( dpkg-query -l ${_dpkg} >/dev/null || echo -1 ) -ge 0 ]]; then
			_pkg=1
		else
			_pkg=0
		fi
	}
#------------------------------------------------------------------------------#
## _user_tests ##
# Function that calls all the user test at program startup
	_user_tests() {
		_su_test
		_sudo_test
		_sudoers_test
	}
#------------------------------------------------------------------------------#
## _su_test ##
# Test if superuser
	_su_test() {
		if [ "$EUID" -ne 0 ]; then
			_note "Using $(whoami) for imagepi"
		else
			_sep
			_error "Permissions issue"
			_note "If running as root, all installations and services must run as root"
			_sep
			exit
		fi
	}
#------------------------------------------------------------------------------#
## _sudoers_test ##
# Test if current user is in the sudoers file
	_sudoers_test() {
		if [ "$EUID" -eq 0 ]; then
			_warning "Not recommeneded to run as root, continue ( y | N )"
			read _ans
			case ${_ans} in
				y) _warning "Continue at your own peril .....";;
				*) _success "Good Call"
					exit ;;
			esac
		else
			_header "Test if current user is in sudoers file"
			if [[ $(getent group sudo | grep $(whoami) 1>/dev/null || echo -1) -ge 0 ]]; then 
				_success "$(whoami) is in the sudo group"
			else
				_warning "$(whoami) is not in the sudo group, aborting...."
			exit
			fi
		fi	
	}
#------------------------------------------------------------------------------#
## _sudo_test ##
# Test if sudo package is installed
	_sudo_test() {
		_dpkg="sudo"
		_header "Testing if ${_dpkg} is installed"
		_dpkg_check
		case ${_pkg} in
			1) _success "${_dpkg} is installed";;
			0) _warning "${_dpkg} is not Installed, Aborting...."
				exit ;;
		esac
	}
#------------------------------------------------------------------------------#
# Execute startup user test
  _user_tests
#------------------------------------------------------------------------------#
## _apt_query_deps ##
# Query apt to test for dependencies
  _apt_query_deps() {
		deps_list="
			qemu
			qemu-user-static
			binfmt-support
			"
		_header "Query apt to test for dependencies"
		for i in ${deps_list}; do
			dpkg-query -Wf'${db:Status-abbrev}' $i 2>/dev/null | grep -q '^i'
			if [[ $? -eq 0 ]]; then
				apt_deps_status=1
				_success "$i : ${apt_deps_status}"
				_deps_status=1
			else
				apt_deps_status=0
				_error "$i : ${apt_deps_status}"
				_deps_status=0
			fi
		done
	}
#------------------------------------------------------------------------------#
## _qemu_arm_status ##
# Query the status of arm in qemu
  _qemu_arm_status() {
		_qemu_status=( `sudo update-binfmts --display | grep ${_qemu_type} | awk 'NR<=1 {print"1"}' `)
		if [[ ${_qemu_status} -eq 1 ]]; then
			_success "qemu-${_qemu_type} : ${_qemu_status}"
			_qemu_bin_static=(`which qemu-${_qemu_type}-static`)
			_success "qemu static binary = ${_qemu_bin_static}"
		else
			_warning "qemu-arm : missing"
			_error "please install qemu-user-static"
		fi
	}
#------------------------------------------------------------------------------#
## _rpi_source_list ##
# Update the sources list in the Raspberry Pi Image
	_rpi_source_list() {
		cd ${_rpi_mount}
		_l0=(
			stretch
			buster
			jessie
			stable
			wheezy
		)
		_header "Choose Dist Version"
		_list_template
		_dist_selected=${_list_output}
		_success "Selected : ${_dist_selected}"
		_l0=(
			Debian
			Raspbian
		)
		_header "Select the apt sources list"
		_list_template
		_selected_source=${_list_output}
		_success "Source selected : ${_selected_source}"
		case ${_selected_source} in
			"Debian") _source_list=${_source_list_deb} ;;
			"Raspbian") _source_list=${_source_list_rpi} ;;
		esac
		_header "sources.list : ${_selected_source}"
		_header "dist selected ${_dist_selected}"
		for i in "${_source_list[@]}"; do
			printf "$i" #>> ${_rpi_mount}/etc/apt/sources.list
		done
		#_source_view=(` cat ${_rpi_mount}/etc/apt/sources.list `)
		#_success "${_source_view}"
	}
#------------------------------------------------------------------------------#
## _rpi_chroot ##
# change root into the Rasberry Pi Image
	_rpi_chroot() {
		_apt_query_deps
		if [[ ${_deps_status} -eq 0 ]]; then
			_error "Missing packages... Unable to chroot"
		else
			_image_mount_yn
			if [[ ${_mnt_status} -eq 1 ]]; then
				_header "Enter chroot"
				_choose "( y | N ) ?"
				read _ans
				_ans_check
				case ${_ans} in
					y|Y) _note "Entering chroot....."
							_success "chrooting into ${_rpi_mount}"
							cd ${_rpi_mount}
							sudo systemd-nspawn -D ${_rpi_mount} bin/bash
							;;
					*) _warning "Aborting...."
							;;
				esac
				_image_umount_yn
			else
				_header "chroot"
				_warning "Not mounted: ${_rpi_img}, Aborting..."
			fi
		fi
	}
#------------------------------------------------------------------------------#
