
FROM node:16-alpine3.15

WORKDIR /usr/src/app

COPY package.json ./

RUN npm install --verbose

# Adicionando `node_modules` para o $PATH
ENV PATH /usr/src/app/node_modules/.bin:$PATH

EXPOSE 3000

CMD ["sleep","infinity"]