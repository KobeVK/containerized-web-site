FROM python:3.8-alpine

COPY ./requirements.txt .
RUN apk add --update --no-cache --virtual .tmp gcc libc-dev linux-headers
RUN pip install -r requirements.txt
RUN apk del .tmp

COPY ./app /home/ubuntu/Greenroad/
WORKDIR /home/ubuntu/Greenroad/