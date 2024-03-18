# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/go/dockerfile-reference/

# Want to help us make this template better? Share your feedback here: https://forms.gle/ybq9Krt8jtBL3iCk7

ARG PYTHON_VERSION=3.12.2
FROM python:${PYTHON_VERSION}-slim as base

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Create a non-privileged user that the app will run under.
# See https://docs.docker.com/go/dockerfile-user-best-practices/
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/home/appuser" \
    --shell "/sbin/nologin" \
    --uid "${UID}" \
    appuser

# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.cache/pip to speed up subsequent builds.
# Leverage a bind mount to requirements.txt to avoid having to copy them into
# into this layer.
RUN pip install -U 'huggingface_hub[cli]'
RUN pip install --upgrade huggingface_hub
RUN pip install -U 'huggingface_hub[cli]'
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=bind,source=requirements.txt,target=requirements.txt \
    python -m pip install -r requirements.txt
# Switch to the non-privileged user to run the application.
RUN chmod -R 755 /app
WORKDIR /app

# Copy the source code into the container.
COPY . .

# Expose the port that the application listens on.
EXPOSE 8000
# Run the application.
CMD pip install -U "jax[cuda12_pip]" -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html --user ; huggingface-cli download xai-org/grok-1 --repo-type model --include ckpt-0/* --local-dir /app/checkpoints --local-dir-use-symlinks False ;  mv /app/checkpoints/ckpt /app/checkpoints/ckpt-0 ; mkdir /root/shm ; sed -i "s;/dev/shm/;/root/shm/;g" /app/checkpoint.py ; pip install -r requirements.txt ; python run.py
