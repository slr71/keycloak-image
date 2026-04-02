#!/usr/bin/env bash

set -e

function check_environment_variables {
    local error_found=""
    for var in "$@"; do
        if [ -z "${!var}" ]; then
            echo "$var environment variable must be set" >&2
            error_found=1
        fi
    done
    if [ -n "$error_found" ]; then
        exit 1
    fi
}

function error_exit {
    local msg="$1"
    echo "$msg" >&2
    exit 1
}

function message_exit {
    local msg="$1"
    echo "$msg"
    exit 0
}

# Verify that all required environment variables are set.
check_environment_variables KC_ADMIN_URL KC_ADMIN_USER KC_ADMIN_PASS KC_ADMIN_EMAIL

# Add the Keycloak bin directory to the path.
PATH=/opt/keycloak/bin:$PATH

# Try authenticating with the actual credentials in case the permanent user already exists.
kcadm.sh config credentials \
         --server "$KC_ADMIN_URL" \
         --realm master \
         --user "$KC_ADMIN_USER" \
         --password "$KC_ADMIN_PASS" \
    && message_exit "user $KC_ADMIN_USER already exists"

# Authenticate with the temporary credentials.
kcadm.sh config credentials \
         --server "$KC_ADMIN_URL" \
         --realm master \
         --user admin \
         --password admin \
    || error_exit "unable to authenticate to admin API"

# Create the permanent admin user.
kcadm.sh create users \
         -s username="$KC_ADMIN_USER" \
         -s email="$KC_ADMIN_EMAIL" \
         -s enabled=true \
         -s emailVerified=true \
         -r master \
    || error_exit "unable to create user $KC_ADMIN_USER"

# Set the permanent admin user password.
kcadm.sh set-password \
         -r master \
         --username "$KC_ADMIN_USER" \
         --new-password "$KC_ADMIN_PASS" \
    || error_exit "unable to set password for $KC_ADMIN_USER"

# Add the admin role to the new admin user.
kcadm.sh add-roles \
         -r master \
         --username "$KC_ADMIN_USER" \
         --rolename admin \
    || error_exit "unable to add admin role to $KC_ADMIN_USER"

# Get the user ID for the temporary admin user.
id=$(kcadm.sh get users -r master -q username=admin -q exact=true -F id --format csv --noquotes)
if [ -z "$id" ]; then
    error_exit "unable to get the temporary admin user ID"
fi

# Delete the temporary admin user.
kcadm.sh delete "users/$id" -r master \
    || error_exit "unable to delete the temporary admin user"
