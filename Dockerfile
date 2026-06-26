FROM quay.io/keycloak/keycloak:26.6 AS builder

# Enable health and metrics support.
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Add the `/auth` path prefix for compatibility with existing OIDC clients.
ENV KC_HTTP_RELATIVE_PATH=/auth

# Configure the database vendor.
ENV KC_DB=postgres

WORKDIR /opt/keycloak

# Add the AI Sandbox authenticator provider JAR.
COPY ai-sandbox-authenticator-0.1.0-standalone.jar /opt/keycloak/providers/

RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:26.6

COPY --from=builder /opt/keycloak/ /opt/keycloak/
COPY ./create-kc-admin.sh /bin/
COPY ./themes/ /opt/keycloak/themes/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
