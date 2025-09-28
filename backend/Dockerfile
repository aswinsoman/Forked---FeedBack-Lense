# Backend API
FROM node:18-alpine
WORKDIR /app
COPY backend/package*.json ./
RUN npm ci --omit=dev
COPY backend ./
ENV NODE_ENV=production PORT=4000
EXPOSE 4000
CMD ["npm", "start"]
