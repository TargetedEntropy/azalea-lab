# =============================================================================
# Azalea-Lab NeoForge Server
# MC 1.21.1 | NeoForge version detected at build time
#
# Includes patches to allow non-NeoForge clients (azalea bot) to connect:
#   1. NegotiationPatch  – bypasses NeoForge channel negotiation
#   2. ConfigInitPatch   – skips registry/feature-flag checks
#   3. checkpatch coremod – disables checkPacket validation via ASM
# =============================================================================

ARG NEOFORGE_VERSION=21.1.219

# --- Stage 1: Install NeoForge and apply Java patches ---
FROM eclipse-temurin:21-jdk AS installer

ARG NEOFORGE_VERSION

WORKDIR /server

# Copy and run the NeoForge installer
COPY pack/neoforge-${NEOFORGE_VERSION}-installer.jar .
RUN java -jar neoforge-${NEOFORGE_VERSION}-installer.jar --installServer && \
    rm -f neoforge-${NEOFORGE_VERSION}-installer.jar

# Compile and inject the negotiation/config patches into the NeoForge jar
COPY patches/NegotiationPatch.java /tmp/patch/net/neoforged/neoforge/network/negotiation/NetworkComponentNegotiator.java
COPY patches/ConfigInitPatch.java  /tmp/patch/net/neoforged/neoforge/network/ConfigurationInitialization.java

RUN CP=$(find /server/libraries -name "*.jar" | tr "\n" ":") && \
    javac -proc:none -cp "$CP" \
        /tmp/patch/net/neoforged/neoforge/network/negotiation/NetworkComponentNegotiator.java \
        /tmp/patch/net/neoforged/neoforge/network/ConfigurationInitialization.java && \
    cd /tmp/patch && \
    jar uf /server/libraries/net/neoforged/neoforge/${NEOFORGE_VERSION}/neoforge-${NEOFORGE_VERSION}-universal.jar \
        net/neoforged/neoforge/network/negotiation/NetworkComponentNegotiator.class \
        'net/neoforged/neoforge/network/negotiation/NetworkComponentNegotiator$ComponentNegotiationResult.class' \
        net/neoforged/neoforge/network/ConfigurationInitialization.class && \
    rm -rf /tmp/patch

# --- Stage 2: Runtime ---
FROM eclipse-temurin:21-jdk

WORKDIR /server

# Copy installed NeoForge (with patches applied)
COPY --from=installer /server /server

# Copy modpack content (only dirs that exist — some packs may omit some)
COPY pack/mods/           /server/mods/
COPY pack/config/         /server/config/
COPY pack/defaultconfigs/ /server/defaultconfigs/
COPY pack/kubejs/         /server/kubejs/
COPY pack/plugins/        /server/plugins/

# Inject the checkPacket coremod into the mods folder
COPY patches/checkpatch-coremod-1.0.0.jar /server/mods/checkpatch-coremod-1.0.0.jar

# Server configuration
COPY pack/user_jvm_args.txt /server/user_jvm_args.txt
COPY config/server.properties /server/server.properties
COPY config/log4j2.xml        /server/log4j2.xml

# Accept EULA
RUN echo "eula=true" > eula.txt

EXPOSE 25565

CMD ["bash", "run.sh"]
