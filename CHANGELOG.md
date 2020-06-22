# Snikket Server changelog

## UNRELEASED

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
