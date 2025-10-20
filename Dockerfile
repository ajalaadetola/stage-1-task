# Use an official Node.js image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files first
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy all app files
COPY . .

# Expose app port
EXPOSE 3000

# Run the app
CMD ["npm", "start"]
