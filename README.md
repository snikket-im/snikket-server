# Snikket builder

This is the source repository for building [Snikket service](https://snikket.org/service/)
Docker images.

## Requirements

 - GNU make
 - docker (tested on 19.03.5)
 - ansible (tested on 2.7 (debian buster))

## Building

Run 'make'

## Running

The easiest way is to use docker-compose. Copy the file `snikket.conf.example` to
`snikket.conf` and edit the values in it. Then run:

  docker-compose up -d

If you need to change port mappings or any other advanced options, you can edit the
docker-compse.yml file.

Alternatively you can run docker manually with something like the following:

docker run --env-file=snikket.conf -p 80:5280 -p 443:5281 -p 5222:5222 -p 5269:5269 snikket

## Development

Dev images have a few additional features.

### Local mail server

Outgoing emails from dev images are captured by a local [MailHog](https://github.com/mailhog/MailHog)
instance and are accessible in a dashboard served on port 8025. The dashboard requires authentication.
The username is 'snikket' and the auto-generated password can be found with the following command:

```
docker exec snikket_snikket_1 cat /tmp/mailhog-password
```

Replace `snikket_snikket_1` with the name of your running container if it differs.

MailHog is not included in production images, which require a real SMTP server.
