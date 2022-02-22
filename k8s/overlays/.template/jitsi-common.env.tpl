# Public URL for the web service.
PUBLIC_URL=https://${BASE_DOMAIN}

# Internal XMPP domain.
XMPP_DOMAIN=${BASE_DOMAIN}

# Internal XMPP domain for authenticated services.
XMPP_AUTH_DOMAIN=auth.${BASE_DOMAIN}

# XMPP domain for unauthenticated users.
XMPP_GUEST_DOMAIN=guest.${BASE_DOMAIN}

# XMPP domain for the internal MUC used for jibri, jigasi and jvb pools.
XMPP_INTERNAL_MUC_DOMAIN=internal-muc.auth.${BASE_DOMAIN}

# XMPP domain for the MUC.
XMPP_MUC_DOMAIN=muc.${BASE_DOMAIN}

# XMPP domain for the jibri recorder
XMPP_RECORDER_DOMAIN=recorder.${BASE_DOMAIN}
