#!/bin/bash
#------------------------------------------------------------------------------#
## _rpi_img_file ##
# Show image file status and layout
	_rpi_img_file() {
		_header "Printing Image information for: ${_rpi_img}"
		_sep
		sudo fdisk -lu ${_rpi_img}
		_sep
		_success "Hit the Any Key to continue....."
		read huh
	}
#------------------------------------------------------------------------------#
## _img_dd_resize ##
# Resize the Raspberry Pi image size
	_img_dd_resize() {
		_header "Making sure the image is not mounted"
			sudo losetup -D
		_success "Done!"
		_header "Choose how much to expand the Image File"
		_note "Amounts in MB"
			_l0=(
				1024
				2048
				4096
				0
				)
			_list_template
			_img_pad=${_list_output}
			if [[ ${_img_pad} -eq 0 ]]; then
				_warning "Nothing to do, Aborting..."
			else
				_header "Increasing  ${_rpi_img} by : ${_img_pad} MB"
				_warning "Continue ( y | N ) ?"
				read _ans
				_ans_check
				case ${_ans} in
					y|Y) _note "Continuing..."
							dd if=/dev/zero bs=1M count=${_img_pad} >> ${_rpi_img}
							;;
					*)	_warning "Aborting..."
							;;
				esac
			fi
	}
#------------------------------------------------------------------------------#
## _img_partition_update ##
# Expand Raspberry Pi Image partition 2
	_img_partition_update() {
		_rpi_img_file
		_img_dd_resize
		if [[ ${_img_pad} -eq 0 ]]; then
				_warning "Nothing to do, Aborting..."
			else
				_loopback_img_test
				_header "Setting partition 2 start position"
				# Getting partition 2 start point
					_img_part_start=$(sudo parted ${_loop_img} print | awk 'length($1) == 1 && $1 ~ 2 { gsub(/MB/,""); print$2}')
					_success "${_loop_img} : Start ${_img_part_start}"
				# Removing partition 2
				_header "Removing partition ${_loop_img}p2"
					sudo parted ${_loop_img} rm 2
				_success "Removed partition ${_loop_img}p2"
				# Expanding partition 2
				_header "Expanding partition ${_loop_img}p2"
					sudo parted ${_loop_img} mkpart primary ${_img_part_start} 100%
				_success "Epanded partition ${_loop_img}p2"
				# Running fsck on partition 2
				_header "Running fsck on partition ${_loop_img}p2"
					sudo e2fsck -f ${_loop_img}p2
				_success "fsck on partition ${_loop_img}p2 complete"
				# Resizing partition 2
				_header "Resizing partition ${_loop_img}p2"
					sudo resize2fs ${_loop_img}p2
				_success "Partition ${_loop_img}p2 resized"
			fi
	}
#------------------------------------------------------------------------------#
## _loopback_img_test ##
# Test if image is already attached to loopback device
	_loopback_img_test() {
		_header "Testing if ${_rpi_img} is attached" 
		if [[ $( sudo losetup -l | grep ${_rpi_img} > /dev/null || echo -1 ) -ge 0 ]];then 
			_warning "${_rpi_img} is already attached, updating loopback variable" 
			_loop_img=$(sudo losetup -l | grep ${_rpi_img} | awk '{print$1}')
			_success "Updated loopback : ${_loop_img}"
		else
			_warning "${_rpi_img} was not attached, updating loopback variable"
			_loop_img=$(sudo losetup -f -P --show ${_rpi_img} | awk '{print$1}')
			_success "Created loopback : ${_loop_img}"
		fi
	}

#------------------------------------------------------------------------------#
## _rpi_mount_dir_test ##
# Test for Raspberry Pi mount directory
	_rpi_mount_dir_test() {
		_header "Testing if ${_rpi_mount} exists"
		if [[ -d ${_rpi_mount} ]]; then
			_success "${_rpi_mount} exists"
		else
			_error "${_rpi_mount} is missing, creating..."
			mkdir ${_rpi_mount}
			if [[ -d ${_rpi_mount} ]]; then
				_success "${_rpi_mount} created"
			else
				_error "Can't create ${_rpi_mount}, Aborting...."
				exit
			fi
		fi
	}
#------------------------------------------------------------------------------#
## _rpi_mount_test ##
# Test image is mounted
	_rpi_mount_test() {
		_header "Testing if ${_loop_img} is mounted"
		sudo mount ${_loop_img}p2 -o rw ${_rpi_mount}
		if [[ $(df | grep "${_loop_img}p2" | awk '{print$1}') == ${_loop_img}p2 ]]; then
			_success "${_loop_img}p2 mounted : /"
			_header "Mount ${_loop_img}p1 : /boot"
			_choose "( y | N )?"
				read _ans
				_ans_check
				case ${_ans} in
					y|Y) _header "Mounting ${_loop_img}p1...."
							sudo mount ${_loop_img}p1 -o rw ${_rpi_mount}/boot
							if [[ $(df | grep "${_loop_img}p1" | awk '{print$1}') == ${_loop_img}p1 ]]; then
								_success "${_loop_img}p1 mounted : /boot"
							else
								_warning "${_loop_img}p1 not mounted, Continuing without boot mounted"
							fi
							;;
					n|N) _header "Skipping ${_loop_img}p1 mount"
							;;
				esac
		else
			_warning "${_loop_img}p2 not mounted, Aborting ...."
			exit
		fi
	}
#------------------------------------------------------------------------------#
## _rpi_image_mount ##
# Mount the Raspberry Pi image
	_rpi_image_mount() {
		_loopback_img_test
		_rpi_mount_dir_test
		_header "Mounting ${_rpi_img}"
		_note "loop device : ${_loop_img}"
		_note "mount point : ${_rpi_mount}"
		_rpi_mount_test
		_qemu_arm_status
		_header "Copying ${_qemu_bin_static} to ${_rpi_img}"
		_warning "Required for chroot"
		sudo cp ${_qemu_bin_static} ${_rpi_mount}/usr/bin
	}
#------------------------------------------------------------------------------#
## _rpi_image_umount ##
# Umount the Raspberry Pi image
  _rpi_image_umount() {
		cd ${SOURCE}
		_loopback_img_test
		if [[ $(df | grep "${_loop_img}p1" | awk '{print$1}') == ${_loop_img}p1 ]]; then
				_header "Umounting ${_rpi_mount}/boot"
				sudo umount ${_rpi_mount}/boot
				_success "Unmounted - ${_loop_img}p1 : ${_rpi_mount}/boot"
		else 
				_warning "Not Mounted - ${_loop_img}p1 : ${_rpi_mount}/boot"
		fi
			sleep 1
		if [[ $(df | grep "${_loop_img}p2" | awk '{print$1}') == ${_loop_img}p2 ]]; then
			_header "Umounting ${_rpi_mount}"
			sudo umount ${_rpi_mount}
			_success "Unmounted - ${_loop_img}p2 : ${_rpi_mount}"
		else
			_warning "Not Mounted - ${_loop_img}p2 : ${_rpi_mount}"
		fi
			sleep 1
    _header "Removing loopback device : ${_loop_img}"
			sudo losetup -d ${_loop_img}
		_success "Removed loopback device : ${_loop_img}"
  }
#------------------------------------------------------------------------------#
## _image_mount_yn ##
# Verify to mount Raspberry Pi Image
	_image_mount_yn() {
		_header "mount : ${_rpi_img}"
		_choose "( y | N ) ?"
			read _ans
			_ans_check
			case ${_ans} in
				y|Y) _rpi_image_mount 
						_mnt_status=1	
						;;
				*)	_warning "Not mounting : ${_rpi_img}, Aborting..."
						_mnt_status=0
						;;
			esac
	}
#------------------------------------------------------------------------------#
## _image_umount_yn ##
# Verify to umount Raspberry Pi Image
	_image_umount_yn() {
		if [[ ${_mnt_status} -eq 1 ]]; then
			_header "Unmount ${_loop_img} : ${_rpi_mount}"
			_choose "( y | N ) ?"
			read _ans
			_ans_check
			case ${_ans} in
				y|Y) _rpi_image_umount ;;
				*)	_warning "Not mounting : ${_rpi_img}, Aborting...";;
			esac
		else
			_warning "Not mounting : ${_rpi_img}, Aborting..."
		fi
	}
#------------------------------------------------------------------------------#