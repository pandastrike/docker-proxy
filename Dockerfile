FROM node:4.3
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY package.json /usr/src/app/
RUN npm install
RUN npm install coffee-script -g
COPY . /usr/src/app

CMD [ "npm", "start" ]

EXPOSE 80
