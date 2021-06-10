# Snikket server images

This is the source repository for building [Snikket service](https://snikket.org/service/)
Docker images.

Snikket is an open-source self-hosted personal messaging service. It aims to
provide an alternative to proprietary and centralized messaging platforms
while supporting all the expected features and being easy to use.

For more information see the [Snikket website](https://snikket.org/).

## Getting Started with Snikket

For instructions on getting started with Snikket, see the [Snikket installation
guide](https://snikket.org/service/quickstart/) on our website.

## Building images

This section is for people who want to build their own images of Snikket, e.g.
for development purposes.

### Requirements

 - GNU make
 - docker (tested on 19.03.5)
 - ansible (tested on 2.7 (debian buster))

### Building

Run `make`

### Running

The easiest way is to use docker-compose. Copy the file `snikket.conf.example` to
`snikket.conf` and edit the values in it. Then run:

```console
docker-compose up -d
```
