FROM nginx:1.27-alpine
COPY index.html app.js config.js /usr/share/nginx/html/
COPY 40-config.sh /docker-entrypoint.d/40-config.sh
RUN sed -i 's/\r$//' /docker-entrypoint.d/40-config.sh && chmod +x /docker-entrypoint.d/40-config.sh

LABEL org.opencontainers.image.source="https://github.com/Pramukh660/fastapi-microk8s-homelab"
EXPOSE 80
