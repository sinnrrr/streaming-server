# Streaming server
### 🤖[`nginx-http-flv-module`](https://github.com/winshining/nginx-http-flv-module) + 💾[`s3fs-fuse`](https://github.com/s3fs-fuse/s3fs-fuse) = ❤️‍🔥
⚡ **Blazingly fast** Docker image, that provides exceptional support for integrating [`Amazon S3`](https://aws.amazon.com/s3/) with [`nginx-http-flv-module`](https://github.com/winshining/nginx-http-flv-module), **which is better, than [nginx-rtmp-module](https://github.com/arut/nginx-rtmp-module)** (see [comparison table](https://github.com/winshining/nginx-http-flv-module#features)), to save the `*.m3u8` files into AWS S3 storage.

Based on https://github.com/efriandika/streaming-server

### What's inside?
* nginx 1.16.1 (stable version compiled from source)
* nginx-http-flv-module 1.2.10 (compiled from source)
* ffmpeg 4.2.1 (compiled from source)
* S3FS FUSE (Amazon S3 Integration)
* Default HLS settings (see [nginx.conf](nginx.conf))

[![Docker Stars](https://img.shields.io/docker/stars/sinnrrr/streaming-server.svg)](https://hub.docker.com/r/efriandika/streaming-server/)
[![Docker Pulls](https://img.shields.io/docker/pulls/sinnrrr/streaming-server.svg)](https://hub.docker.com/r/efriandika/streaming-server/)
[![Docker Automated build](https://img.shields.io/docker/automated/efriandika/streaming-server.svg)](https://hub.docker.com/r/efriandika/streaming-server/builds/)
[![Circle CI](https://circleci.com/gh/sinnrrr/streaming-server.svg?style=shield&circle-token=:circle-token)](https://circleci.com/gh/sinnrrr/streaming-server)

## Usage

Run container from source:
```bash
docker run --rm -it \
  -e AWS_ACCESS_KEY_ID=secret \
  -e AWS_SECRET_ACCESS_KEY=secret \
  -e AWS_S3_BUCKET_NAME=secret \
  -e AWS_S3_REGION=us-east-1 \
  --cap-add=SYS_ADMIN --device="/dev/fuse" --security-opt="apparmor=unconfined" \
  -p 1935:1935 -p 8080:80 -p 8443:443 sinnrrr/streaming-server
```

`docker-compose.yml` can be:
```yaml
streaming-server:
  image: sinnrrr/streaming-server:latest
  env_file:
    - .env # I encourage you to use .env file
  ports:
    - 1935:1935
    - 8080:80
    - 8443:443
  cap_add:
    - SYS_ADMIN
  devices:
    - /dev/fuse
  security_opt:
    - apparmor:unconfined
```

## Streaming live content 
### Using RTMP
```
rtmp://<server_ip>:1935/stream/<stream_name>
```

### OBS Configuration
To stream from OBS go to `Settings -> Stream`, and input the following:
* Stream Type: `Custom Streaming Server`
* URL: `rtmp://localhost:1935/stream` (stream name is "stream")
* Stream Key: `hello` (it could be anything, but we will use this for sake of example)

## Consuming live content
### Using `localhost`
* In your browser, VLC or any HLS player, open:
```
http://localhost:8080/live/<stream_key>.m3u8
```

Following our example, `<stream_key>` is `hello`, so:
* Access playlist using URL: `http://localhost:8080/live/hello.m3u8`
* Play online using [VideoJS Player](https://video-dev.github.io/hls.js/stable/demo/?src=http%3A%2F%2Flocalhost%3A8080%2Flive%2Fhello.m3u8)
* FFplay: `ffplay -fflags nobuffer rtmp://localhost:1935/stream/hello`

### Using AWS S3
>  ATTENTION:
>  Don't forget to set public access and enable CORS in your S3 bucket

You can access your livescream playlist using your S3 public URL.

For example: `https://<s3_bucket_name>.s3.us-east-1.amazonaws.com/hls/hello.m3u8`

or you can set your CloudFront (cache disabled) distribution then based on your S3.


## Configuration

### SSL (optional)
To enable SSL, see [nginx.conf](nginx.conf) and uncomment the lines:
```
listen 443 ssl;
ssl_certificate     /opt/certs/example.com.crt;
ssl_certificate_key /opt/certs/example.com.key;
```

This will enable HTTPS using a self-signed certificate supplied in [/certs](/certs). If you wish to use HTTPS, it is **highly recommended** to obtain your own certificates and update the `ssl_certificate` and `ssl_certificate_key` paths.

I recommend using [Certbot](https://certbot.eff.org/docs/install.html) from [Let's Encrypt](https://letsencrypt.org).

### Environment variables
| Variable name         | Default value              | Required |
|-----------------------|----------------------------|----------|
| AWS_ACCESS_KEY_ID     | -                          | true     |
| AWS_SECRET_ACCESS_KEY | -                          | true     |
| AWS_BUCKET_NAME       | -                          | true     |
| AWS_S3_AUTHFILE       | `/etc/passwd-s3fs`         | false    |
| AWS_S3_MOUNTPOINT     | `/opt/data`                | false    |
| AWS_S3_URL            | `https://s3.amazonaws.com` | false    |
| AWS_S3_REGION         | `us-east-1`                | false    |
| S3FS_ARGS             | -                          | false    |

### `ffmpeg` build information
```
$ ffmpeg -buildconf

ffmpeg version 4.2.1 Copyright (c) 2000-2019 the FFmpeg developers
  built with gcc 6.4.0 (Alpine 6.4.0)
  configuration: --prefix=/usr/local --enable-version3 --enable-gpl --enable-nonfree --enable-small --enable-libmp3lame --enable-libx264 --enable-libx265 --enable-libvpx --enable-libtheora --enable-libvorbis --enable-libopus --enable-libfdk-aac --enable-libass --enable-libwebp --enable-librtmp --enable-postproc --enable-avresample --enable-libfreetype --enable-openssl --disable-debug --disable-doc --disable-ffplay --extra-libs='-lpthread -lm'
  libavutil      56. 31.100 / 56. 31.100
  libavcodec     58. 54.100 / 58. 54.100
  libavformat    58. 29.100 / 58. 29.100
  libavdevice    58.  8.100 / 58.  8.100
  libavfilter     7. 57.100 /  7. 57.100
  libavresample   4.  0.  0 /  4.  0.  0
  libswscale      5.  5.100 /  5.  5.100
  libswresample   3.  5.100 /  3.  5.100
  libpostproc    55.  5.100 / 55.  5.100

  configuration:
    --prefix=/usr/local
    --enable-version3
    --enable-gpl
    --enable-nonfree
    --enable-small
    --enable-libmp3lame
    --enable-libx264
    --enable-libx265
    --enable-libvpx
    --enable-libtheora
    --enable-libvorbis
    --enable-libopus
    --enable-libfdk-aac
    --enable-libass
    --enable-libwebp
    --enable-librtmp
    --enable-postproc
    --enable-avresample
    --enable-libfreetype
    --enable-openssl
    --disable-debug
    --disable-doc
    --disable-ffplay
    --extra-libs='-lpthread -lm'
```

## Resources
* https://github.com/winshining/nginx-http-flv-module
* https://github.com/s3fs-fuse/s3fs-fuse
* http://nginx.org
* https://alpinelinux.org/
* https://www.ffmpeg.org
* https://obsproject.com
