### APP LAYER

FROM rimantoro/go-filebeat-alpine:1.0.0

ARG APPENV="dev"
ARG APPMODE="server"
ARG WORKERNAME="gotrial_worker_1"
ARG QUEUENAME="gotrial_transaction"
ARG DBHOST=""
ARG DBNAME=""
ARG DBUSER=""
ARG DBPASS=""
ARG ENCRYPT_KEY=""

ENV APPENV=${APPENV}
ENV APPMODE=${APPMODE}
ENV WORKERNAME=${WORKERNAME}
ENV QUEUENAME=${QUEUENAME}
ENV DBHOST=${DBHOST}
ENV DBNAME=${DBNAME}
ENV DBUSER=${DBUSER}
ENV DBPASS=${DBPASS}
ENV ENCRYPT_KEY=${ENCRYPT_KEY}

RUN apk add --update tzdata wget git gcc libc-dev make openssl;

RUN go get -u github.com/golang/dep/cmd/dep

ADD . $GOPATH/src/gotrial
WORKDIR $GOPATH/src/gotrial

CMD if [ "$APPMODE" = "debug" ] ; then \
        dep ensure -v && sleep 3600s ; \
    else \
        echo "DEBUG >>> APPENV=$APPENV APPMODE=$APPMODE" \
        && echo "DEBUG >>> host=$DBHOST user=$DBUSER dbname=$DBNAME sslmode=disable password=$DBPASS" \
        && dep ensure -v \
        && if [ "$APPENV" = "dev" ] ; then \
            go build -v -o $GOPATH/bin/gotrial \
            && gotrial mysql "host=$DBHOST user=$DBUSER dbname=$DBNAME sslmode=disable password=$DBPASS" up \
            && if [ "$APPMODE" = "server" ] ; then gotrial run ; \
                elif [ "$APPMODE" = "worker" ] ; then gotrial start_worker "$WORKERNAME" "$QUEUENAME" ; \
                elif [ "$APPMODE" = "test" ] ; then go test tests/*_test.go -count=1 -failfast -coverpkg=./api,./worker/jobs -coverprofile=cover.out  ; \
                else echo "Invalid APPMODE" ; \
            fi \   
        fi \
    fi 

EXPOSE 8000
