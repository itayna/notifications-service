# Build stage pinned to the builder's native arch: the jar is arch-independent,
# so Maven never runs under QEMU emulation. Only the small runtime stage is
# built per target platform.
FROM --platform=$BUILDPLATFORM maven:3.9.16-eclipse-temurin-25 AS build
WORKDIR /build
COPY pom.xml .
RUN mvn -B dependency:go-offline
# Checkstyle is bound to validate, which mvn package runs: without the ruleset
# the in-image build fails even though CI's mvn verify passed outside it.
COPY checkstyle.xml .
COPY src ./src
RUN mvn -B package -DskipTests

FROM eclipse-temurin:25-jre-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=build /build/target/*.jar app.jar
USER app
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
