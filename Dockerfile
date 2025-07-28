# Stage 1: Build the React front-end
FROM node:18-alpine as builder
WORKDIR /app/gke-react-front
COPY gke-react-front/package*.json ./
RUN npm install
COPY gke-react-front/ ./
RUN npm run build

# Stage 2: Serve the back-end and front-end
FROM node:18-alpine
WORKDIR /app
# Copy the built front-end from the builder stage
COPY --from=builder /app/gke-react-front/build ./gke-react-front-build
# Copy the back-end source code
COPY gke-node-backend ./gke-node-backend
WORKDIR /app/gke-node-backend
RUN npm install
# Expose the port your Node.js app runs on
EXPOSE 3000
# Set the entrypoint to run the Node.js back-end
CMD ["npm", "start"]
