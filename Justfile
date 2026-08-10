repotag := "harbor.cyverse.org/de/keycloak:26.6"
authenticator-dir := justfile_directory() + "/../ai-sandbox-authenticator"
authenticator-jar := "ai-sandbox-authenticator-0.1.0-standalone.jar"

build:
    cd "{{authenticator-dir}}" && clojure -T:build uber
    cp "{{authenticator-dir}}/target/{{authenticator-jar}}" .
    rm -rf themes/ai-sandbox
    cp -r "{{authenticator-dir}}/resources/theme/ai-sandbox" themes/
    docker buildx build --no-cache --platform linux/amd64 -t "{{repotag}}" .
    rm -f "{{authenticator-jar}}"

push:
    docker push "{{repotag}}"
