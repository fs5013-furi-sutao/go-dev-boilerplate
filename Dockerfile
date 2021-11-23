FROM golang:1.16.3-alpine

ENV GO111MODULE on

WORKDIR /go/src/app

RUN apk update \
  && apk add git \
  gcc \
  musl-dev 
RUN go install github.com/cosmtrek/air@latest 
RUN go install golang.org/x/tools/gopls@latest 
RUN go get -u \
  github.com/ramya-rao-a/go-outline \
  github.com/uudashr/gopkgs/v2/cmd/gopkgs \
  github.com/nsf/gocode \
  github.com/acroca/go-symbols \
  github.com/fatih/gomodifytags \
  github.com/josharian/impl \
  github.com/haya14busa/goplay/cmd/goplay \
  golang.org/x/lint/golint 
# div-dap のインストール方法は次のドキュメントを参考にしました:
# https://github.com/golang/vscode-go/blob/v0.26.0/docs/dlv-dap.md#updating-dlv-dap
RUN GOBIN=/tmp/ go get github.com/go-delve/delve/cmd/dlv@master \
  && mv /tmp/dlv $GOPATH/bin/dlv-dap
