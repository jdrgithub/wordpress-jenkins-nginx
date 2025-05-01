FROM nginx:alpine

COPY nginx-start.sh /etc/nginx/nginx-start.sh
COPY nginx.prod.conf /etc/nginx/nginx.prod.conf
COPY nginx.dev.conf /etc/nginx/nginx.dev.conf

RUN chmod +x /etc/nginx/nginx-start.sh

ENTRYPOINT ["/etc/nginx/nginx-start.sh"]

