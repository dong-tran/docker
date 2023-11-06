FROM alpine

# Install ArgoCD CLI
ENV VERSION=v2.8.4 
RUN wget -O argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
RUN install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
RUN rm argocd-linux-amd64
