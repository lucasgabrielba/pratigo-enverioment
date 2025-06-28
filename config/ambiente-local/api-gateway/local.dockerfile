FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --legacy-peer-deps
COPY . .
EXPOSE 4090
CMD ["npm", "run" ,"start-with-migrations"]
