FROM alpine:3.4
MAINTAINER Matthieu Larcher <mlarcher@ringabell.org>

# Set working directory to be the home directory
WORKDIR /

# Set default Unison configuration
ENV UNISON_WORKING_DIR=/data
ENV UNISON_PORT=9010

# Setup unison to run as a service
VOLUME $UNISON_WORKING_DIR
EXPOSE $UNISON_PORT

# Upload Unison for building
COPY output/alpine/unison /bin/unison

CMD ["/bin/sh", "-c", "cd ${UNISON_WORKING_DIR} && unison -socket ${UNISON_PORT}"]







