FROM quay.io/keycloak/keycloak:26.5 AS builder

# Enable health and metrics support.
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Configure the database vendor.
ENV KC_DB=postgres

WORKDIR /opt/keycloak
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:26.5

COPY --from=builder /opt/keycloak/ /opt/keycloak/
COPY ./create-kc-admin.sh /bin/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
