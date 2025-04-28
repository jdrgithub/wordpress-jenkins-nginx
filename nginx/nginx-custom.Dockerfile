FROM nginx:alpine

COPY nginx-start.sh /etc/nginx/nginx-start.sh
RUN chmod +x /etc/nginx/nginx-start.sh

ENTRYPOINT ["/etc/nginx/nginx-start.sh"]

