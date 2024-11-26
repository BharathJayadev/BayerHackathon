# Use the official Node.js image as the base image
FROM node:16

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json into the working directory
COPY package*.json ./

# Install application dependencies
RUN npm install

# Copy the application source code into the container
COPY . .

# Expose the port the app runs on
EXPOSE 3002

# Command to run the application
CMD ["node", "index.js"]
