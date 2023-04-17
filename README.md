<p align="center">
  <a href="https://hub.docker.com/r/pumtrix/fnm-webui/tags?page=1&ordering=last_updated"><img src="https://img.shields.io/github/v/tag/pumtrix/fnm-webui?label=version&style=flat-square" alt="Latest Version"></a>
  <a href="https://github.com/pumtrix/fnm-webui/actions?workflow=build"><img src="https://img.shields.io/github/actions/workflow/status/pumtrix/fnm-webui/build.yml?branch=master&label=build&logo=github&style=flat-square" alt="Build Status"></a>
  <a href="https://hub.docker.com/r/pumtrix/fnm-webui/"><img src="https://img.shields.io/docker/stars/pumtrix/fnm-webui.svg?style=flat-square&logo=docker" alt="Docker Stars"></a>
  <a href="https://hub.docker.com/r/pumtrix/fnm-webui/"><img src="https://img.shields.io/docker/pulls/pumtrix/fnm-webui.svg?style=flat-square&logo=docker" alt="Docker Pulls"></a>
</p>

## About

Docker image for [FNM WebUI](https://github.com/Pumtrix-Tech/fnm-webui/), a web interface for [FastNetMon](https://fastnetmon.com).

## Special thanks

We would like to thank [@crazy-max](https://github.com/crazy-max) for his work on the LibreNMS docker repo which this is based on.

> **Note**
> 
> Want to be notified of new releases? Check out 🔔 [Diun (Docker Image Update Notifier)](https://github.com/crazy-max/diun)
> project!

___

* [Features](#features)
* [Build locally](#build-locally)
* [Image](#image)
* [Environment variables](#environment-variables)
  * [General](#general)
  * [Database](#database)
* [Volumes](#volumes)
* [Ports](#ports)
* [Usage](#usage)
  * [Docker Compose](#docker-compose)
  * [Command line](#command-line)
  * [First launch](#first-launch)
* [Upgrade](#upgrade)
* [Notes](#notes)
  * [artisan command](#artisan-command)
* [Contributing](#contributing)
* [License](#license)

## Features

* Multi-platform image
* OPCache enabled to store precompiled script bytecode in shared memory
* [s6-overlay](https://github.com/just-containers/s6-overlay/) as process supervisor
* [MariaDB](https://github.com/docker-library/mariadb) image as database instance

## Build locally

```console
$ git clone https://github.com/Pumtrix-Tech/fnm-webui-docker.git
$ cd fnm-webui-docker

# Build image and output to docker (default)
$ docker buildx bake

# Build multi-platform image
$ docker buildx bake image-all
```

## Image

Following platforms for this image are available:

```
$ docker run --rm mplatform/mquery pumtrix/fnm-webui:latest
Image: pumtrix/fnm-webui:latest
 * Manifest List: Yes
 * Supported platforms:
   - linux/amd64
   - linux/arm/v6
   - linux/arm/v7
   - linux/arm64
   - linux/386
   - linux/ppc64le
   - linux/s390x
```

## Environment variables

### General

* `TZ`: The timezone assigned to the container (default `UTC`)
* `PUID`: FNM WebUI user id (default `1000`)
* `PGID`: FNM WebUI group id (default `1000`)
* `MEMORY_LIMIT`: PHP memory limit (default `256M`)
* `MAX_INPUT_VARS`: PHP max input vars (default `1000`)
* `UPLOAD_MAX_SIZE`: Upload max size (default `16M`)
* `CLEAR_ENV`: Clear environment in FPM workers (default `yes`)
* `FPM_PM_MAX_CHILDREN`: FPM max Children (default: `15`)
* `FPM_PM_START_SERVERS`: FPM start servers (default: `2`)
* `FPM_PM_MIN_SPARE_SERVERS`: FPM min spare servers (default: `1`)
* `FPM_PM_MAX_SPARE_SERVERS`: FPM max spare servers (default: `6`)
* `OPCACHE_MEM_SIZE`: PHP OpCache memory consumption (default `128`)
* `LISTEN_IPV6`: Enable IPv6 for Nginx (default `true`)
* `REAL_IP_FROM`: Trusted addresses that are known to send correct replacement addresses (default `0.0.0.0/32`)
* `REAL_IP_HEADER`: Request header field whose value will be used to replace the client address (default `X-Forwarded-For`)
* `LOG_IP_VAR`: Use another variable to retrieve the remote IP address for access [log_format](http://nginx.org/en/docs/http/ngx_http_log_module.html#log_format) on Nginx. (default `remote_addr`)
* `SESSION_DRIVER`: [Driver to use for session storage](https://github.com/Pumtrix-Tech/fnm-webui/blob/master/config/session.php) (default `file`)
* `CACHE_DRIVER`: [Driver to use for cache and locks](https://github.com/Pumtrix-Tech/fnm-webui/blob/master/config/cache.php) (default `database`)

### Database

* `DB_HOST`: MySQL database hostname / IP address
* `DB_PORT`: MySQL database port (default `3306`)
* `DB_NAME`: MySQL database name (default `fnmwebui`)
* `DB_USER`: MySQL user (default `fnmwebuis`)
* `DB_PASSWORD`: MySQL password (default `fnmwebuis`)
* `DB_TIMEOUT`: Time in seconds after which we stop trying to reach the MySQL server (useful for clusters, default `60`)

## Volumes

* `/data`: Contains configuration for future use

> **Warning**
>
> Note that the volume should be owned by the user/group with the specified
> `PUID` and `PGID`. If you don't give the volume correct permissions, the
> container may not start.

## Ports

* `8000`: HTTP port

## Usage

### Docker Compose

Docker compose is the recommended way to run this image. Copy the content of
folder [examples/compose](examples/compose) in `/var/fnm-webui/` on your host
for example. Edit the compose and env files with your preferences and run the
following commands:

```console
$ docker-compose up -d
$ docker-compose logs -f
```

### Command line

You can also use the following minimal command:

```console
$ docker run -d -p 8000:8000 --name fnm-webui \
  -v $(pwd)/data:/data \
  -e "DB_HOST=db" \
  pumtrix/fnm-webui:latest
```

> **Warning**
>
> `db` must be a running MySQL instance.

### First launch

Default user account:

username: admin@localhost
password: password

When you first access the webui, please make sure that you change the default password and update to a correct email address.

> **Note**
>
> If you lose access, you can create another one using the [`artisan` command](#artisan-command).

## Upgrade

To upgrade to the latest version of FNM WebUI, pull the newer image and launch
the container.

```console
$ docker-compose down
$ docker-compose pull
$ docker-compose up -d
```

Then run:

```console
artisan migrate
```

## Notes

### artisan command

If you want to use the `artisan` command to perform common server operations like
manage users, database migration, and more, type:

```console
$ docker-compose exec fnm-webui artisan
```

## Contributing

Want to contribute? Awesome! The most basic way to show your support is to star the project, or to raise issues. You
can also support this project by submitting pull requests to this docker repo or the main code base.

Thanks again for your support, it is much appreciated! :pray:

## License

MIT. See `LICENSE` for more details.
