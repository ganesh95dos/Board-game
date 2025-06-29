# ---- Stage 1: Build ----
FROM maven:3.9.6-eclipse-temurin-17 AS builder
WORKDIR /app

# 1. Copy only pom.xml to cache dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# 2. Copy source code
COPY src ./src

# 3. Package the app
RUN mvn clean package -DskipTests

# ---- Stage 2: Final image ----
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
