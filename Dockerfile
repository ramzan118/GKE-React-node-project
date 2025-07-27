# Stage 1: Build React frontend
FROM node:16 AS frontend
WORKDIR /app
COPY gke-react-front/package*.json ./
RUN npm install
COPY gke-react-front/ ./
RUN npm run build

# Stage 2: Build Node backend
FROM node:16
WORKDIR /app
COPY gke-node-backend/package*.json ./
RUN npm install --production
COPY gke-node-backend/ ./
COPY --from=frontend /app/build ./public

ENV PORT=8000
EXPOSE $PORT
CMD ["node", "server.js"]
