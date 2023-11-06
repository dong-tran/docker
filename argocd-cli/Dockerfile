FROM alpine

# Install ArgoCD CLI
ENV VERSION=v2.8.4
ARG TARGETPLATFORM

RUN wget -O argocd-cli https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-${TARGETPLATFORM#*/}
RUN install -m 555 argocd-cli /usr/local/bin/argocd
RUN rm argocd-cli
