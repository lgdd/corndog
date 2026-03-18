FROM maven:3.8-openjdk-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn package -DskipTests

FROM eclipse-temurin:17-jre
WORKDIR /app
RUN mkdir -p /exports /app/data

ADD https://dtdg.co/latest-java-tracer /app/dd-java-agent.jar

COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-javaagent:/app/dd-java-agent.jar", "-jar", "app.jar"]
