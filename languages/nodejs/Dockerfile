FROM node:16

RUN uname -r

# print versions
RUN node --version && npm --version && curl --version

WORKDIR /app

COPY . ./

CMD node ./index.js
