# Stage to build tini
# Reference: https://github.com/krallin/tini-images/blob/master/autogen/centos-7/Dockerfile
FROM centos:7 as TiniBuilder
RUN TINI_VERSION="v0.13.2" \
    && TINI_REAL_VERSION="0.13.2" \
    && TINI_BUILD="/tmp/tini" \
    && echo "Installing build dependencies" \
    && TINI_DEPS="gcc cmake make git rpm-build glibc-static curl tar libcap-devel python-devel" \
    && yum history new || yum history new \
    && mv /sbin/weak-modules /sbin/weak-modules.tmp \
    && yum install --assumeyes ${TINI_DEPS} \
    && echo "Building Tini" \
    && git clone https://github.com/krallin/tini.git "${TINI_BUILD}" \
    && cd "${TINI_BUILD}" \
    && curl -O https://pypi.python.org/packages/source/v/virtualenv/virtualenv-13.1.2.tar.gz \
    && tar -xf virtualenv-13.1.2.tar.gz \
    && mv virtualenv-13.1.2/virtualenv.py virtualenv-13.1.2/virtualenv \
    && export PATH="${TINI_BUILD}/virtualenv-13.1.2:${PATH}" \
    && HARDENING_CHECK_PLACEHOLDER="${TINI_BUILD}/hardening-check/hardening-check" \
    && HARDENING_CHECK_PLACEHOLDER_DIR="$(dirname "${HARDENING_CHECK_PLACEHOLDER}")" \
    && mkdir "${HARDENING_CHECK_PLACEHOLDER_DIR}" \
    && echo  "#/bin/sh" > "${HARDENING_CHECK_PLACEHOLDER}" \
    && chmod +x "${HARDENING_CHECK_PLACEHOLDER}" \
    && export PATH="${PATH}:${HARDENING_CHECK_PLACEHOLDER_DIR}" \
    && git checkout "${TINI_VERSION}" \
    && export SOURCE_DIR="${TINI_BUILD}" \
    && export BUILD_DIR="${TINI_BUILD}" \
    && export ARCH_NATIVE=1 \
    && "${TINI_BUILD}/ci/run_build.sh" \
    && mv "${TINI_BUILD}/tini_${TINI_REAL_VERSION}.rpm" "/tmp/tini.rpm"

# Final Stage
FROM centos:7
LABEL maintainer="mirco.tracolli@pg.infn.it"
LABEL Version=1.0

# Reference for EL7 Worker Node
# wn metapackage: https://twiki.cern.ch/twiki/bin/view/LCG/EL7WNMiddleware 

# Update system and install wget
RUN echo "LC_ALL=C" >> /etc/environment \
    && echo "LANGUAGE=C" >> /etc/environment \
    && yum --setopt=tsflags=nodocs -y update \
    && yum --setopt=tsflags=nodocs -y install wget \
    && yum clean all

# Add yum repos
WORKDIR /etc/yum.repos.d
RUN wget http://repository.egi.eu/community/software/preview.repository/2.0/releases/repofiles/centos-7-x86_64.repo \
    && wget http://repository.egi.eu/sw/production/cas/1/current/repo-files/EGI-trustanchors.repo 

# Add grid stuff
WORKDIR /root
RUN yum --setopt=tsflags=nodocs -y install epel-release yum-plugin-ovl \
    && yum --setopt=tsflags=nodocs -y install fetch-crl wn \
    && yum clean all

# Add tini from previous build stage
COPY --from=TiniBuilder /tmp/tini.rpm /tmp
RUN yum --setopt=tsflags=nodocs -y install /tmp/tini.rpm \
    && rm /tmp/tini.rpm \
    && yum clean all \
    && echo "Symlinkng to /usr/local/bin" \
    && ln -s /usr/bin/tini /usr/local/bin/tini \
    && ln -s /usr/bin/tini-static /usr/local/bin/tini-static \
    && echo "Running Smoke Test" \
    # Param -s is used to prevent warning:
    #
    #     [WARN  tini (12)] Tini is not running as PID 1 and 
    #       isn't registered as a child subreaper.
    #     Zombie processes will not be re-parented to Tini,
    #       so zombie reaping won't work.
    #     To fix the problem, use the -s option or set the environment
    #       variable TINI_SUBREAPER to register Tini as a child subreaper, 
    #       or run Tini as PID 1.
    && /usr/bin/tini -s -- ls \
    && /usr/bin/tini-static -s -- ls \
    && /usr/local/bin/tini -s -- ls \
    && /usr/local/bin/tini-static -s -- ls \
    && echo "Done"

ENTRYPOINT ["/usr/bin/tini", "--"]
