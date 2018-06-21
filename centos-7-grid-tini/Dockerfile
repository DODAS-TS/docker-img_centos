# Final Stage
FROM dodasts/centos:7-grid

RUN TINI_VERSION="v0.18.0" \
    && if [ `uname -i` == "x86_64" ]; then PLATFORM="-amd64"; else PLATFORM=""; fi \
    && wget "https://github.com/krallin/tini/releases/download/v0.18.0/tini_0.18.0$PLATFORM.rpm" -O /tmp/tini.rpm \
    && yum --setopt=tsflags=nodocs -y install /tmp/tini.rpm \
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
