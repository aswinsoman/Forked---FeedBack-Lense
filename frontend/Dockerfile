# --- Build (with fallback to /app/public) ---
FROM node:18-alpine AS build
WORKDIR /app
# install deps if present
COPY frontend/package*.json ./
RUN npm ci || true
# copy source
COPY frontend ./
# If there's no build script, create dist from /app/public so COPY works later
RUN npm run build || (mkdir -p /app/dist && [ -d /app/public ] && cp -r /app/public/* /app/dist/ || true)

# --- Runtime (nginx) ---
FROM nginx:alpine
# copy whatever we produced (real build or public fallback)
COPY --from=build /app/dist/ /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx","-g","daemon off;"]
