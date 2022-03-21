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

## Authentication

# Enable authentication
ENABLE_AUTH=0

# Enable guest access
ENABLE_GUESTS=1

# Select authentication type: internal, jwt or ldap
AUTH_TYPE=internal

# Application identifier.
#JWT_APP_ID=my_app_id

# Authenticate using external service or just focus external auth window if
# there is one already.
#TOKEN_AUTH_URL=https://auth.meet.example.com/{room}
