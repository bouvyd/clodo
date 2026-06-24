# Odoo development image.
# Python version is pinned to Odoo 19.0's primary supported target (3.12, the
# "Noble" pins in requirements.txt). Built on Debian 12 (bookworm) so the
# official wkhtmltopdf .deb installs cleanly.
ARG PYTHON_BASE=python:3.12-bookworm
FROM ${PYTHON_BASE}

ARG USER_NAME=odoo
ARG USER_UID=1000
ARG USER_GID=1000
ARG WKHTMLTOPDF_VERSION=0.12.6.1-3
ARG WKHTMLTOPDF_DISTRO=bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    LANG=C.UTF-8

# --- System dependencies -----------------------------------------------------
# Build toolchain + headers needed to compile psycopg2, python-ldap, lxml,
# Pillow, gevent/greenlet, plus runtime libs, fonts and the postgres client.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
        gnupg \
        less \
        libcairo2-dev \
        libffi-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        liblcms2-dev \
        libldap2-dev \
        libpq-dev \
        libsasl2-dev \
        libssl-dev \
        libtiff5-dev \
        libwebp-dev \
        libxml2-dev \
        libxslt1-dev \
        libyaml-dev \
        pkg-config \
        zlib1g-dev \
        node-less \
        nodejs \
        npm \
        postgresql-client \
        sudo \
        wget \
        fonts-liberation \
        fonts-noto-cjk \
        fonts-noto-color-emoji \
        locales; \
    rm -rf /var/lib/apt/lists/*

# --- wkhtmltopdf (patched build used by Odoo for PDF reports) -----------------
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    url="https://github.com/wkhtmltopdf/packaging/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox_${WKHTMLTOPDF_VERSION}.${WKHTMLTOPDF_DISTRO}_${arch}.deb"; \
    wget -q "$url" -O /tmp/wkhtmltox.deb; \
    apt-get update; \
    apt-get install -y --no-install-recommends /tmp/wkhtmltox.deb; \
    rm -rf /tmp/wkhtmltox.deb /var/lib/apt/lists/*; \
    wkhtmltopdf --version

# rtlcss is required by Odoo to compile RTL (right-to-left) web assets.
RUN npm install -g rtlcss && npm cache clean --force

# --- Non-root user matching the host UID/GID ---------------------------------
# Keeps files created in the rw-mounted source repos owned by your host user.
RUN set -eux; \
    if ! getent group "${USER_GID}" >/dev/null; then groupadd -g "${USER_GID}" "${USER_NAME}"; fi; \
    groupname="$(getent group "${USER_GID}" | cut -d: -f1)"; \
    useradd -m -u "${USER_UID}" -g "${USER_GID}" -s /bin/bash "${USER_NAME}"; \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"${USER_NAME}"; \
    chmod 0440 /etc/sudoers.d/"${USER_NAME}"

# --- Python virtualenv with Odoo's pinned dependencies -----------------------
ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv "${VIRTUAL_ENV}" && "${VIRTUAL_ENV}"/bin/pip install --no-cache-dir -U pip setuptools wheel
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"
# Login/interactive shells (e.g. VSCode terminals) reset PATH from /etc/profile;
# re-prepend the venv so `python`/`pip` resolve to it there too.
RUN printf 'export PATH=%s/bin:$PATH\n' "${VIRTUAL_ENV}" > /etc/profile.d/00-venv.sh \
    && printf 'export PATH=%s/bin:$PATH\n' "${VIRTUAL_ENV}" >> /etc/bash.bashrc

COPY requirements.odoo.txt /tmp/requirements.odoo.txt
COPY requirements.dev.txt /tmp/requirements.dev.txt
RUN pip install --no-cache-dir -r /tmp/requirements.odoo.txt -r /tmp/requirements.dev.txt
RUN chown -R "${USER_UID}:${USER_GID}" "${VIRTUAL_ENV}"

# --- odoo launcher wrapper ---------------------------------------------------
# `odoo <args>` runs odoo-bin from the mounted source. The config is provided
# via ODOO_RC (below) rather than -c, so subcommands (`odoo shell`, `odoo
# scaffold`, ...) still parse correctly — odoo-bin only treats the FIRST arg as
# the command, and a leading `-c` would make it fall back to `server`.
ENV ODOO_RC=/workspace/.devcontainer/odoo.conf
RUN printf '%s\n' \
    '#!/usr/bin/env bash' \
    'exec /opt/venv/bin/python /workspace/src/odoo/odoo-bin "$@"' \
    > /usr/local/bin/odoo && chmod +x /usr/local/bin/odoo

USER ${USER_NAME}
WORKDIR /workspace
