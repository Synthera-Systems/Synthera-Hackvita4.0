FROM node:20-slim

# Set working directory
WORKDIR /app

# Copy backend package files first
COPY backend/package*.json ./

# Install backend dependencies
RUN npm install --production

# Copy backend source code
COPY backend/ .

# HuggingFace uses port 7860
ENV PORT=7860
EXPOSE 7860

# Start backend server
CMD ["node", "src/index.js"]
