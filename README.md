# Snikket builder

This is the source repository for building [Snikket service](https://snikket.org/service/)
Docker images.

## Requirements

 - GNU make
 - docker (tested on 19.03.5)
 - ansible (tested on 2.7 (debian buster))

## Building

Run `make`

## Running

The easiest way is to use docker-compose. Copy the file `snikket.conf.example` to
`snikket.conf` and edit the values in it. Then run:

```console
docker-compose up -d
```
