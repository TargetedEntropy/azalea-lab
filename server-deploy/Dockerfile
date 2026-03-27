# =============================================================================
# Azalea-Lab NeoForge Server
# MC 1.21.1 | NeoForge version detected at build time
#
# The azalea-bridge coremod (dropped into mods/) handles all client
# compatibility via ASM bytecode transformation at class-load time.
# No NeoForge jar modifications needed.
# =============================================================================

ARG NEOFORGE_VERSION=21.1.219

# --- Stage 1: Install NeoForge ---
FROM eclipse-temurin:21-jdk AS installer

ARG NEOFORGE_VERSION

WORKDIR /server

COPY pack/neoforge-${NEOFORGE_VERSION}-installer.jar .
RUN java -jar neoforge-${NEOFORGE_VERSION}-installer.jar --installServer && \
    rm -f neoforge-${NEOFORGE_VERSION}-installer.jar

# --- Stage 2: Runtime ---
FROM eclipse-temurin:21-jdk

WORKDIR /server

# Copy installed NeoForge (unmodified)
COPY --from=installer /server /server

# Copy modpack content
COPY pack/mods/           /server/mods/
COPY pack/config/         /server/config/
COPY pack/defaultconfigs/ /server/defaultconfigs/
COPY pack/kubejs/         /server/kubejs/
COPY pack/plugins/        /server/plugins/

# Drop the azalea-bridge coremod into mods/
COPY patches/azalea-bridge-2.0.0.jar /server/mods/azalea-bridge-2.0.0.jar

# Server configuration
COPY pack/user_jvm_args.txt /server/user_jvm_args.txt
COPY config/server.properties /server/server.properties
COPY config/log4j2.xml        /server/log4j2.xml

# Accept EULA
RUN echo "eula=true" > eula.txt

EXPOSE 25565

CMD ["bash", "run.sh"]
