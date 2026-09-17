# Stage 1: Build the Dart server to native executable
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# Stage 2: Run with minimal image + SQLite native library
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends libsqlite3-0 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /app/bin/server /app/bin/server

WORKDIR /app
EXPOSE 8080

CMD ["/app/bin/server"]
