FROM maven:3.6-jdk-11 as build

WORKDIR /app

COPY ./ .
RUN mkdir /maven && mvn -Dmaven.repo.local=/maven -B dependency:go-offline
RUN mvn -Dmaven.repo.local=/maven package

FROM adoptopenjdk:11-jre-hotspot as app

RUN apt-get update
RUN apt-get install -y wget

WORKDIR /app

COPY --from=build /app .

# CMD ./stall.sh
CMD ["java", "-Xmx362m", "-jar", "/app/target/Spammer-0.0.1-jar-with-dependencies.jar"]
