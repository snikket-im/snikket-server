# Snikket Server changelog

## beta.20210205

- Fix destruction of circle group chats when a circle
    is deleted or fails to be created
- Add circle group chats to bookmarks of newly-added members
- Add trailing '/' to invite URLs for compatibility with some
    URL parsers

## beta.20210202

- Support for Raspberry Pi and other ARM-based systems
- Add HTTP admin API for web portal
- Add support for user groups (circles)
- Switch to multi-container architecture (see note below)
- Add support for update and security notifications
- Increase file sharing limit from 10MB -> 16MB

### Upgrading

If you are upgrading from a previous version, this version
requires updates to your `docker-compose.yml`. You can find
a [new version here](https://snikket.org/service/resources/docker-compose.beta.yml).

Make a backup of your current docker-compose.yml if desired,
then put the new one in its place. For example:

```
mv docker-compose.yml docker-compose.old.yml
wget -O docker-compose.yml https://snikket.org/service/resources/docker-compose.beta.yml
docker-compose pull
docker-compose up -d --remove-orphans
```

You may also want to check out our new repository of scripts to help
manage a self-hosted Snikket instance:
[snikket-im/snikket-selfhosted](https://github.com/snikket-im/snikket-selfhosted)

## alpha.20200624

- Add support for generating account recovery links
- Fix group chat creation glitches
- Increase file sharing limit from 1MB -> 10MB
- Enable Prosody admin shell for debug purposes

## alpha.20200525

- Fix for the TURN service auth configuration that prevented some A/V calls from working

## alpha.20200513

- Add STUN/TURN service to facilitate audio/video calls (see note below)
- Restrict 'General Chat' to local users only
- Fix hanging on `docker stop`

If you are upgrading from a previous version, this version requires some changes
in how you run Snikket. Please see the [upgrade notes](https://gist.github.com/mwild1/aa2af95b520bd44283d9062e7846a874)!

## alpha.0

- Initial release!
