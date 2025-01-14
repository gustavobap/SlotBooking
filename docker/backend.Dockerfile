FROM ruby:alpine3.17 AS base

ARG PROJECT

ARG UNAME
ARG UID
ARG UPASSWORD

ARG DB_HOST
ARG DB_USER
ARG DB_PASSWORD

ARG GIT_UNAME
ARG GIT_UEMAIL

RUN apk --no-cache add build-base tzdata bash
RUN apk --no-cache add postgresql-dev
RUN apk --no-cache add git vim

RUN adduser -S -G wheel \
    --uid "${UID}" \
    "${UNAME}"

RUN echo "${UNAME}:${UPASSWORD}" | chpasswd;

ENV DB_HOST ${DB_HOST}
ENV DB_USER ${DB_USER}
ENV DB_PASSWORD ${DB_PASSWORD}

FROM base as development

ARG PROJECT
ARG UNAME
ARG GIT_UNAME
ARG GIT_UEMAIL

RUN apk --no-cache add sudo busybox-suid
RUN echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel

USER ${UNAME}
WORKDIR "/home/${UNAME}/${PROJECT}"

RUN git config --global user.name "${GIT_UNAME}"
RUN git config --global user.email "${GIT_UEMAIL}"

ENTRYPOINT ["/bin/bash"]

FROM base as production

ARG PROJECT
ARG UNAME
ARG WORKD="/home/${UNAME}/${PROJECT}"

COPY --chown=${UNAME}:wheel "./home/${PROJECT}" ${WORKD}
RUN chown -R ${UNAME} "/home/${UNAME}"

USER ${UNAME}
WORKDIR ${WORKD}

RUN gem install bundler
RUN bundle install
RUN EDITOR="nano" bundle exec rails credentials:edit

ENTRYPOINT RAILS_ENV=production bundle exec rake db:prepare && rails server -b 0.0.0.0 -e production