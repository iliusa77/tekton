FROM alpine:3.20

COPY app-in-docker.sh /app/app.sh

RUN chmod +x /app/app.sh

CMD ["/app/app.sh"]