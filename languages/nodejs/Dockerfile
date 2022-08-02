FROM node:16

RUN uname -r

# print versions
RUN node --version && npm --version && curl --version

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm install

COPY index.js ./

CMD ["node", "./index.js"]
