# Stage 1: Build the React Frontend
FROM node:20-alpine AS react-builder
WORKDIR /app/gke-react-front
COPY gke-react-front/package*.json ./
RUN npm install
COPY gke-react-front/ ./
RUN npm run build

# Stage 2: Build the Node.js Backend
FROM node:20-alpine AS node-builder
WORKDIR /app/gke-node-backend
COPY gke-node-backend/package*.json ./
RUN npm install --production
COPY gke-node-backend/ ./

# Final Stage: Combine and Serve
FROM node:20-alpine
WORKDIR /app

# Copy Node.js backend from node-builder stage
COPY --from=node-builder /app/gke-node-backend ./gke-node-backend

# Copy React build artifacts into the Node.js backend's public/static serving directory
# ASSUMPTION: Your Node.js app serves static files from a 'public' directory.
# Adjust this path if your Node.js app uses a different static serving directory.
RUN mkdir -p ./gke-node-backend/public
COPY --from=react-builder /app/gke-react-front/build ./gke-node-backend/public

# Set environment variables for Node.js application
ENV PORT=8080
ENV SPANNER_CONNECTION_STRING_SECRET_ID=${SPANNER_CONNECTION_SECRET_ID} # Used by app to fetch secret

# Expose the port the Node.js application listens on
EXPOSE 8080

# Command to run the Node.js application
# ASSUMPTION: Your main server file is server.js inside gke-node-backend
CMD ["node", "./gke-node-backend/server.js"]
