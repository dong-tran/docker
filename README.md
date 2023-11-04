# docker

# ECR Login
```
aws ecr get-login-password --region <AWS_REGION> --profile <AWS_PROFILE> | docker login --username AWS --password-stdin <ECR_REPO>
```

# Dockerhub Login
```
docker login -u <USERNAME>
```

# Build and push
```
docker buildx build --platform linux/amd64 -t <REPO> -f ./Dockerfile . --push
```
