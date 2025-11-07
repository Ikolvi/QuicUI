# Official Dart image: https://hub.docker.com/_/dart
# Use stable Dart SDK for QuicUI Backend
FROM dart:stable AS build

# Set working directory
WORKDIR /app

# Copy pubspec files first for dependency caching
COPY pubspec.* ./
RUN dart pub get

# Copy entire app source code
COPY . .

# Ensure packages are up-to-date
RUN dart pub get --offline

# AOT compile the server for optimal performance
RUN dart compile exe bin/server.dart -o bin/server

# Build minimal serving image from AOT-compiled `/server`
# This creates a much smaller production image
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/

# Expose port (Render.com will override with $PORT env var)
EXPOSE 8080

# Start QuicUI Backend Server
CMD ["/app/bin/server"]
