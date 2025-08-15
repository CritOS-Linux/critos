#               cX0Okxxxxxkk0Kx               
#           XKOkxxxxxxxxxxxxxxxkOKN'          
#        k0kxxxxxxxxxxxxxxxxxxxxxxxx0X        
#      XOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkK.     
#    OkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkX    
#   0xxxxxxxxxxxxxxxxxdoooodxxddxxxxxxxxxxO.  
#  0xxxxxxxxxxxxxxo;.........' cxxxxxxxxxxxO. 
# kxxxxxxxxxxxxxo. .:oxxxxxxo:.lxxxxxxxxxxxxk 
#:xxxxxxxxxxxxx: .lxxxxxxxxxxxxxxxxxxxxxxxxxxl
#dxxxxxxxxxxxxl .xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
#xxxxxxxxxxxxx. oxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
#dxxxxxxxxxxxx. oxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
#lxxxxxxxxxxxxc 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
#,xxxxxxxxxxxxx, 'dxxxxxxxxxxxxxxxxxxxxxxxxxx:
# lxxxxxxxxxxxxxc. ,ldxxxxxxdcoxxxxxxxxxxxxxx 
#  dxxxxxxxxxxxxxxl'. ..''.. .,dxxxxxxxxxxxx. 
#   dxxxxxxxxxxxxxxxxdlccccldxxxxxxxxxxxxxx   
#    :xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd    
#      dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx      
#        ;xxxxxxxxxxxxxxxxxxxxxxxxxxxl        
#           lxxxxxxxxxxxxxxxxxxxxxd           
#                dxxxxxxxxxxxx.               
#                    ,oxd;
#
# CritOS Containerfile
# Maintainer: CritOS <critos-linux.github.io>

# Base image Settings
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-kinoite}"
ARG BASE_IMAGE_FLAVOR="${BASE_IMAGE_FLAVOR:-main}"
ARG FEDORA_VERSION="${FEDORA_VERSION:-42}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME-$BASE_IMAGE_FLAVOR}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"

####################
# Build for Desktops
####################

FROM ${BASE_IMAGE}:${FEDORA_VERSION} AS critos

# CritOS Image Settings
ARG IMAGE_NAME="${IMAGE_NAME:-critos}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-critos-linux}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"
ARG SHA_HEAD_SHORT="${SHA_HEAD_SHORT}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG NVIDIA_FLAVOR="${NVIDIA_FLAVOR:-nvidia}"
ARG NVIDIA_BASE="${NVIDIA_BASE:-critos}"

COPY system-rootfs/desktop/shared system-rootfs/desktop/${BASE_IMAGE_NAME} /

# Setup COPR Repos and RPM Fusion
RUN mkdir -p /var/roothome && \
    dnf5 -y install dnf5-plugins && \
    for copr in \
        critos-org/critos \
        ublue-os/packages \
        ublue-os/staging; \
    do \
        echo "Enabling COPR REPO: $copr"; \
        dnf5 copr enable -y $copr && \
        dnf5 -y config-manager setopt copr:copr.fedorainfracloud.org:${copr////:}.priority=98 ;\
    done && unset -v copr && \
    dnf5 -y install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    ostree container commit


# Install Some packages
RUN \
    dnf5 -y install \
        uupd \
        lutris \
        steam && \
    ostree container commit

# Remove packages
RUN \
    dnf5 -y remove \
        firefox \
        firefox-langpacks && \
    dnf5 -y autoremove && \
    dnf5 clean all && \
    ostree container commit

# Cleanup and Finalize
COPY system-rootfs/overrides /
RUN --mount=type=bind,source=${PWD}/build-tools,target=/mnt/build-tools \
    bash /mnt/build-tools/image-info

RUN --mount=type=bind,source=${PWD}/build-tools,target=/mnt/build-tools \
    bash /mnt/build-tools/initramfs-build

RUN --mount=type=bind,source=${PWD}/build-tools,target=/mnt/build-tools \
    bash /mnt/build-tools/Finalize

RUN dnf5 config-manager setopt skip_if_unavailable=1 && \
    bootc container lint


# TODO - Kernel, Deck Builds, NVIDIA, etc.

