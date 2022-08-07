# Downloader build stage
FROM ubuntu as downloader

ARG KUBECTL_VERSION=v1.24.3
ARG K9S_VERSION=v0.26.3
ARG TTYD_VERSION=1.6.3

# Download all files to /src
WORKDIR /src

# Setup necessary tools
RUN apt update
RUN apt install -y wget curl

# Download k9s
RUN case $(uname -m) in i386) architecture="x86_64";; i686) architecture="x86_64";; x86_64) architecture="x86_64";; arm|aarch64) dpkg --print-architecture | grep -q "arm64" && architecture="arm64" || architecture="arm" ;; esac && (curl -L -s --output k9s.tar.gz "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${architecture}.tar.gz")
RUN tar zxvf k9s.tar.gz
RUN chmod u+x k9s

# Download ttyd
RUN case $(uname -m) in i386) architecture="x86_64";; i686) architecture="x86_64";; x86_64) architecture="x86_64";; arm|aarch64) dpkg --print-architecture | grep -q "arm64" && architecture="aarch64" || architecture="arm" ;; esac && (curl -L -s --output ttyd "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${architecture}")
RUN chmod u+x ttyd

# Download kubectl
RUN case $(uname -m) in i386) architecture="386";; i686) architecture="386";; x86_64) architecture="amd64";; arm|aarch64) dpkg --print-architecture | grep -q "arm64" && architecture="arm64" || architecture="arm" ;; esac && (curl -L -s --output kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${architecture}/kubectl")
RUN chmod u+x kubectl

# Main build
FROM ubuntu

# Copy from downloader
COPY --from=downloader /src/kubectl /bin/kubectl
COPY --from=downloader /src/ttyd /bin/ttyd
COPY --from=downloader /src/k9s /bin/k9s

# Expect the kubeconfig to be a volume that is passed accordingly
ENV KUBECONFIG=/kubeconfig/config

# Start ttyd, always exit with 1 even on a clean exit to autoreconnect/restart k9s
CMD /bin/ttyd sh -c '/bin/k9s; exit 1'
