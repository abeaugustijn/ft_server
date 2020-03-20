#!/bin/bash
docker stop server; docker rm server
docker run -it -p 110:110 -p 80:80 -p 443:443  --name=server ft_server
