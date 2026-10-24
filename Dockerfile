FROM python:3.11.6-slim-bookworm AS base


FROM base AS build
ARG SOURCE_DATE_EPOCH=0
SHELL [ "/bin/sh", "-eu", "-c" ]
WORKDIR /build

RUN python -m pip install \
  --no-color \
  --no-cache-dir \
  --disable-pip-version-check \
  --no-python-version-warning \
  --no-warn-script-location \
  --break-system-packages \
  --progress-bar off \
  poetry poetry-plugin-export setuptools wheel

COPY pyproject.toml poetry.lock README.md ./
RUN mkdir -p dist \
  && poetry export \
    --without-hashes \
    --format constraints.txt \
    --output dist/constraints.txt \
  && poetry run \
    python -m pip wheel \
     --isolated \
     --requirement dist/constraints.txt \
     --wheel-dir dist/vendor

COPY src/ src/
RUN poetry build --format wheel


FROM base AS final
ARG SOURCE_DATE_EPOCH=0
SHELL [ "/bin/sh", "-eu", "-c" ]
LABEL org.opencontainers.image.source="https://github.com/MeepOK17/devops-final"

ARG USER=audit
ARG HOME=/app
ARG UID=1001
ARG GID=1001
RUN \
  addgroup --gid "${GID}" "${USER}" \
  && adduser --disabled-password --gecos "" \
       --home "${HOME}" --ingroup "${USER}" --uid "${UID}" "${USER}"

WORKDIR ${HOME}
COPY --from=build /build/dist/ dist/
RUN packages=$(\
    find 'dist' 'dist/vendor' \
      -maxdepth 1 \
      -iname '*.whl' \
      -exec realpath {} \; \
      -print0 \
     | xargs --null) \
  && python -m pip install \
    --isolated \
    --no-index \
    --no-color \
    --no-cache-dir \
    --disable-pip-version-check \
    --no-python-version-warning \
    --no-warn-script-location \
    --no-deps \
    --break-system-packages \
    --progress-bar off \
    ${packages} \
  && rm -rf dist

USER ${USER}
ENV PORT="8080" \
    AUDIT_SVC_CONFIG="/etc/audit-svc/config.yaml" \
    PYTHONUNBUFFERED="1"
EXPOSE 8080/tcp
CMD [ "server" ]
