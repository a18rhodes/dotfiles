ARG WORKDIR=/app
FROM python:3.14-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
# uv: copy deps instead of hardlinking (safe across mount boundaries), use the
# image's system Python rather than fetching a managed one, and put the project
# venv at a fixed path so the interpreter location is predictable.
ENV UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0 \
    UV_PROJECT_ENVIRONMENT=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"
# Pin a digest or version tag in real use; :latest is not reproducible.
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
RUN apt-get update && apt-get install -y \
    curl \
    git \
    vim \
    build-essential \
    sudo \
    # Uncomment for projects with C extensions (e.g. scikit-build-core):
    # cmake \
    # Uncomment for projects that build Sphinx docs requiring pandoc:
    # pandoc \
    && rm -rf /var/lib/apt/lists/*
ARG WORKDIR
WORKDIR ${WORKDIR}
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

FROM base AS dependencies
# Cache third-party deps on the lock alone; the project itself is installed
# later so source edits don't bust this layer.
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-install-project --no-dev

FROM dependencies AS development
ARG WORKDIR
# Pass e.g. "--group dev --group test" from devcontainer.json build args.
# Empty string (the default) runs a plain uv sync --frozen with no extra groups.
ARG UV_EXTRA_ARGS=""
COPY . .
RUN uv sync --frozen ${UV_EXTRA_ARGS} \
    && chown -R vscode:vscode ${WORKDIR} /opt/venv
USER vscode
