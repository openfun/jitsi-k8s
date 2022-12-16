#!/bin/sh

prosodyctl --config /config/prosody.cfg.lua register $JIGASI_XMPP_USER $XMPP_RECORDER_DOMAIN $JIGASI_XMPP_PASSWORD
