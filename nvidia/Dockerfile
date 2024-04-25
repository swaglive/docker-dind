ARG         base=archlinux

###

FROM        ${base} as dep-base

RUN         pacman -Sy --noconfirm \
                base-devel \
                bmake \
                lsb-release \
                rpcsvc-proto && \
            # See https://github.com/NVIDIA/nvidia-container-toolkit/issues/113
            pacman -U --noconfirm https://archive.archlinux.org/packages/g/go/go-2:1.20.7-1-x86_64.pkg.tar.zst && \
            mkdir -p -m 0777 /.cache

###

FROM        dep-base as dep-nvidia-container-toolkit

ARG         version_libnvidia_container=
ARG         version_nvidia_container_toolkit=

WORKDIR     /tmp

RUN         curl --parallel \
                --output libnvidia-container.tar.gz https://gitlab.archlinux.org/archlinux/packaging/packages/libnvidia-container/-/archive/${version_libnvidia_container}/libnvidia-container-${version_libnvidia_container}.tar.gz \
                --output nvidia-container-toolkit.tar.gz https://gitlab.archlinux.org/archlinux/packaging/packages/nvidia-container-toolkit/-/archive/${version_nvidia_container_toolkit}/nvidia-container-toolkit-${version_nvidia_container_toolkit}.tar.gz && \
            runuser -u nobody -- \
                mkdir -p libnvidia-container && \
                tar -xvz --strip-components 1 -C libnvidia-container -f libnvidia-container.tar.gz && \
            runuser -u nobody -- \
                mkdir -p nvidia-container-toolkit && \
                tar -xvz --strip-components 1 -C nvidia-container-toolkit -f nvidia-container-toolkit.tar.gz && \
            (\
                cd libnvidia-container && \
                export pkgver=$(grep -Po '(?<=pkgver=).*$' PKGBUILD) && \
                runuser -u nobody -- \
                    makepkg -f --cleanbuild && \
                cp libnvidia-container-${pkgver}-1-x86_64.pkg.tar.zst libnvidia-container.pkg.tar.zst && \
                cp libnvidia-container-tools-${pkgver}-1-x86_64.pkg.tar.zst libnvidia-container-tools.pkg.tar.zst && \
                pacman -U libnvidia-container.pkg.tar.zst libnvidia-container-tools.pkg.tar.zst \
            ) && \
            (\
                cd nvidia-container-toolkit && \
                export pkgver=$(grep -Po '(?<=pkgver=).*$' PKGBUILD) && \
                runuser -u nobody -- \
                    makepkg -f --cleanbuild && \
                cp nvidia-container-toolkit-${pkgver}-1-x86_64.pkg.tar.zst nvidia-container-toolkit.pkg.tar.zst \
            )

###

FROM        ${base} as dep-docker

ARG         version=

ADD         https://archive.archlinux.org/packages/d/docker/docker-1:${version}-1-x86_64.pkg.tar.zst /tmp/docker.pkg.tar.zst

###

FROM        ${base}

ARG         version=

ENV 	    DOCKER_VERSION=${version}
ENV 	    DOCKER_TLS_CERTDIR=/certs

VOLUME 	    /var/lib/docker
EXPOSE 	    2375/tcp
EXPOSE      2376/tcp

ENTRYPOINT  ["dockerd-entrypoint.sh"]

# COPY        --from=dep-docker /tmp/docker.pkg.tar.zst .
# COPY        --from=dep-nvidia-container-toolkit /tmp/libnvidia-container/libnvidia-container.pkg.tar.zst .
# COPY        --from=dep-nvidia-container-toolkit /tmp/libnvidia-container/libnvidia-container-tools.pkg.tar.zst .
# COPY        --from=dep-nvidia-container-toolkit /tmp/nvidia-container-toolkit/nvidia-container-toolkit.pkg.tar.zst .

RUN         pacman -Sy --noconfirm \
                curl \
                ca-certificates \
                iptables \
                inetutils \
                openssl \
                kmod && \
            pacman -S --noconfirm docker && \
            # pacman -U --noconfirm \
            #     docker.pkg.tar.zst && \
            export version_major=$(echo ${version} | cut -d. -f1) && \
            curl -s --parallel \
                --output /usr/local/bin/modprobe https://raw.githubusercontent.com/docker-library/docker/master/${version_major}/cli/modprobe.sh \
                --output /usr/local/bin/dockerd-entrypoint.sh https://raw.githubusercontent.com/docker-library/docker/master/${version_major}/dind/dockerd-entrypoint.sh \
                --output /usr/local/bin/dind https://raw.githubusercontent.com/moby/moby/v${version}/hack/dind && \
            chmod +x \
                /usr/local/bin/modprobe \
                /usr/local/bin/dockerd-entrypoint.sh \
                /usr/local/bin/dind && \
            mkdir -p /certs /certs/client /etc/docker && \
            chmod 1777 /certs /certs/client && \
            dockerd --version && \
            containerd --version && \
            ctr --version && \
            runc --version && \
            # pacman -U --noconfirm \
            #     libnvidia-container.pkg.tar.zst \
            #     libnvidia-container-tools.pkg.tar.zst \
            #     nvidia-container-toolkit.pkg.tar.zst && \
            pacman -S --noconfirm nvidia-container-toolkit && \
            nvidia-ctk runtime configure --runtime=docker && \
            rm -rf *.pkg.tar.zst
