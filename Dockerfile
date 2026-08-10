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

# Add themes so that kc.sh build can process and cache them.
COPY ./themes/ /opt/keycloak/themes/

RUN /opt/keycloak/bin/kc.sh build --feature-token-exchange=enabled --feature-admin-fine-grained-authz=v1

FROM quay.io/keycloak/keycloak:26.6

COPY --from=builder /opt/keycloak/ /opt/keycloak/
COPY ./create-kc-admin.sh /bin/
COPY ./themes/ /opt/keycloak/themes/

# Tell Keycloak's folder theme provider where to find filesystem themes.
# Without this, the provider falls back to deriving the path from kc.home.dir
# which may not be set correctly at runtime, causing custom themes to be invisible.
ENV KC_SPI_THEME_FOLDER_DIR=/opt/keycloak/themes

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
