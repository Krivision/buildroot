################################################################################
#
# COBALT
#
################################################################################

COBALT_VERSION = 01e0507bff2dcba83fffc0ef6f21d4d1b7d5f6bc
COBALT_SITE_METHOD = git
COBALT_SITE = git@github.com:krivision/cobalt
COBALT_INSTALL_STAGING = YES
COBALT_DEPENDENCIES = host-cmake host-ninja host-python3 host-python-six host-nodejs host-gn ffmpeg

define COBALT_BUILD_CMDS
endef

define COBALT_INSTALL_STAGING_CMDS
endef

define COBALT_INSTALL_TARGET_CMDS
endef

$(eval $(generic-package))
