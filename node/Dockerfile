FROM node:14

RUN apt-get update && apt-get install -y jq

RUN uname -r

# print versions
RUN node --version && npm --version && curl --version

WORKDIR /app

COPY . ./

RUN npm install

# docker startup
RUN echo '#!/bin/bash\nnode index.js' > app.sh
RUN chmod +x app.sh
CMD ./app.sh
