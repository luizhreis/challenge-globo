FROM python:3.7.4-slim

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8000

ENTRYPOINT ["/app/scripts/entrypoint.sh"]
