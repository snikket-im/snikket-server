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

If you need to change port mappings or any other advanced options, you can edit the
`docker-compse.yml` file.

Alternatively you can run docker manually with something like the following:

```console
docker run --env-file=snikket.conf -p 80:5280 -p 443:5281 -p 5222:5222 -p 5269:5269 snikket
```
