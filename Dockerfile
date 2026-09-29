FROM eclipse-temurin:17-jdk
WORKDIR /app

COPY /build/libs/service.jar app.jar

EXPOSE 8095
ENTRYPOINT ["java", "-jar", "app.jar"]
