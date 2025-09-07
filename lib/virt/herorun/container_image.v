module herorun

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.osal.tmux
import freeflowuniverse.herolib.osal.core as osal
import time
import freeflowuniverse.herolib.builder
import json



@[heap]
pub struct ContainerImage {
pub:
	image_name string @[required] //image is located in /containers/images/<image_name>/rootfs
	docker_unc string //optional
	
}

pub struct ContainerImageArgs {
pub:
	image_name string @[required] //image is located in /containers/images/<image_name>/rootfs
	docker_unc string 
	reset bool
}


pub fn (mut self ContainerFactory) image_new(args ContainerImageArgs) !&ContainerImage {
	//if docker unc is given, we need to download the image and extract it to /containers/images/<image_name>/rootfs, use podman for it
	//if podman not installed give error
	//attach image to self.factory.images ..
}

pub fn (mut self ContainerFactory) images_list() ![]&ContainerImage {
	//TODO: ...
}



//TODO: export to .tgz file
pub fn (mut self ContainerImage) export(...) !{
	//export dir if exist to the define path, if not exist then error
}


pub fn (mut self ContainerImage) import(...) !{
	//import from .tgz file to /containers/images/<image_name>/rootfs, if already exist give error, unless if we specify reset
}

pub fn (mut self ContainerImage) delete() !{
	//TODO:
}
