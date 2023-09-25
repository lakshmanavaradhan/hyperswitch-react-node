FROM node:14
COPY hyperswitch-react-node /opt/hyperswitch-react-node
RUN cd /opt/hyperswitch-react-node && npm install 
EXPOSE 3000
WORKDIR /opt/hyperswitch-react-node
CMD ["npm", "run", "start-client"]
