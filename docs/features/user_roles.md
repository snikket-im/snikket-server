---
title: User roles
---

# User roles

Snikket allows you to select a role for users, each role granting different
permissions.

Each user may have one of three roles:

## Administrator

This is the default role of the first user (if you're reading this, that's
probably you!).

Administrators have full control over the server, settings, users and circles.
These features can be accessed primarily through the admin panel in the
Snikket web interface.

## Normal

This is the default role for most users. It gives access to all
non-administrative server functionality.

## Limited

Limited users have various restrictions. The purpose of this role is to
allow granting someone an account on the server, only for the purposes of
communicating with other people on that server. This can be useful to provide
a guest or child account, for example.

In particular, limited users are not allowed to:

- Communicate with users on other servers
- Join group chats on other servers
- Create public channels (including on the current server)
- Invite new users to the server (regardless of whether this is enabled for
  normal users).

### Caveats

The current support for limited users has some known issues. It is designed to
prevent casual misuse of the server, but it is not intended to be a foolproof
security measure. For example, limited users are still able to *receive*
messages and contact requests from other servers, even though they cannot send
them to other servers. It is expected that we will restrict incoming traffic
for limited users in a future release, after further testing.

Also note that limited accounts may have issues using non-Snikket mobile apps
that use push notifications, depending on the design of the app. This is
because the restrictions may prevent the app communicating with its'
developer's push notification services over XMPP.
