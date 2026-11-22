# Build the Flutter Web app in a reproducible Flutter SDK image.
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter analyze --no-fatal-warnings --no-fatal-infos
RUN flutter test
RUN flutter build web --release --base-href /

# Serve the compiled app as a static site.
FROM nginx:alpine
COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 10000
CMD ["nginx", "-g", "daemon off;"]
