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
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG NVIDIA_FLAVOR="${NVIDIA_FLAVOR:-nvidia}"
ARG NVIDIA_BASE="${NVIDIA_BASE:-critos}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"
ARG SHA_HEAD_SHORT="${SHA_HEAD_SHORT}"
ARG FEDORA_VERSION="${FEDORA_VERSION:-42}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME-$BASE_IMAGE_FLAVOR}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"

FROM scratch AS ctx
COPY build-tools /

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
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-kinoite}"
ARG BASE_IMAGE_FLAVOR="${BASE_IMAGE_FLAVOR:-main}"
ARG FEDORA_VERSION="${FEDORA_VERSION:-42}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME-$BASE_IMAGE_FLAVOR}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"

COPY system-rootfs/desktop/shared system-rootfs/desktop/${BASE_IMAGE_NAME} /

# Setup COPR Repos and RPM Fusion
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    mkdir -p /var/roothome && \
    dnf5 -y install dnf5-plugins && \
    for copr in \
        @critos-org/critos  \
        ublue-os/packages \
        ublue-os/staging; \
    do \
        echo "Enabling COPR REPO: $copr"; \
        dnf5 copr enable -y $copr && \
        dnf5 -y config-manager setopt copr:copr.fedorainfracloud.org:${copr////:}.priority=98; \
    done && unset -v copr && \
    dnf5 -y install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    /ctx/cleanup


# Install New packages
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 -y install \
        uupd \
        lutris \
        steam \
        gamescope \
        mangohud \
        yafti \
        p7zip \
        fastfetch \
        input-remapper \
        iwd && \
    sed -i 's|uupd|& --disable-module-distrobox|' /usr/lib/systemd/system/uupd.service && \
    /ctx/cleanup

# Plasma/GNOME Configuration
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    if grep -q "kinoite" <<< ${BASE_IMAGE_NAME}; then \
        dnf5 -y install \
            qt \
            krdp \
            kdeconnectd \
            kdeplasma-addons \
            gnome-disk-utility && \
        dnf5 -y remove \
            plasma-welcome \
            plasma-welcome-fedora \
            kcharselect \
            kde-partitionmanager; \
    else \
        dnf5 -y remove \
            gnome-classic-session \
            gnome-tour; \
    fi && \
    /ctx/cleanup


# Remove packages
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 -y remove \
        firefox \
        firefox-langpacks && \
    dnf5 -y autoremove && \
    dnf5 clean all && \
    /ctx/cleanup

# Cleanup and Finalize
COPY system-rootfs/overrides /
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    systemctl --global enable podman.socket && \
    systemctl enable uupd.service && \
    /ctx/image-info && \
    /ctx/initramfs-build && \
    /ctx/finalize

RUN dnf5 config-manager setopt skip_if_unavailable=1 && \
    bootc container lint


################
# Build for Deck
################

FROM critos AS critos-deck

ARG IMAGE_NAME="${IMAGE_NAME:-critos-deck}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-critos-linux}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG NVIDIA_FLAVOR="${NVIDIA_FLAVOR:-nvidia}"
ARG NVIDIA_BASE="${NVIDIA_BASE:-critos}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-kinoite}"
ARG FEDORA_VERSION="${FEDORA_VERSION:-42}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"


COPY system-rootfs/deck/shared system-rootfs/deck/${BASE_IMAGE_NAME} /


# Install Gamescope session packages
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 -y install \
        gamescope-session-plus \
        gamescope-session-steam && \
    /ctx/cleanup

RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    systemctl enable critos-autologin && \
    ln -s /usr/bin/steamos-logger /usr/bin/steamos-info && \
    ln -s /usr/bin/steamos-logger /usr/bin/steamos-notice && \
    ln -s /usr/bin/steamos-logger /usr/bin/steamos-warning && \
     /ctx/image-info && \
    /ctx/initramfs-build && \
    /ctx/finalize

RUN dnf5 config-manager setopt skip_if_unavailable=1 && \
    bootc container lint

##################
# Build for NVIDIA
##################

FROM ${NVIDIA_BASE} AS critos-nvidia

ARG IMAGE_NAME="${IMAGE_NAME:-critos-nvidia}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-critos-linux}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-nvidia}"
ARG NVIDIA_FLAVOR="${NVIDIA_FLAVOR:-nvidia}"
ARG NVIDIA_BASE="${NVIDIA_BASE:-critos}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-kinoite}"
ARG FEDORA_VERSION="${FEDORA_VERSION:-42}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"

RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/install-nvidia && \
    /ctx/cleanup && \
    /ctx/image-info && \
    /ctx/initramfs-build && \
    /ctx/finalize

RUN dnf5 config-manager setopt skip_if_unavailable=1 && \
    bootc container lint

# TODO - Kernel.

