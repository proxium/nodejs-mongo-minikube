SHELL := /bin/bash
image-name="local.dev:30007/nodejs-hello:1.1"
cluster-prod="prod-cluster"
cluster-dev="dev-cluster"
dns-prod="local.prod"
dns-dev="local.dev"
dev-password:=$(shell head -c 256 /dev/random | openssl sha512 -binary | base64 | tr -dc A-Za-z1-9 | cut -b1-10)
prod-password:=$(shell head -c 256 /dev/random | openssl sha512 -binary | base64 | tr -dc A-Za-z1-9 | cut -b1-10)

dev: build initdev updatehost-dev push run-dev
prod: build initprod updatehost-prod push run-prod
all: dev prod

build:
	docker build -t $(image-name) .

initdev:
	minikube start -p $(cluster-dev) \
		--disk-size='10000mb' \
		--driver=hyperkit \
		--addons=ingress \
		--insecure-registry="local.dev:30007" \
		--memory 3072 \
		--dns-domain=$(dns-dev) --extra-config=kubelet.cluster-domain=$(dns-dev)

	kubectl config use-context $(cluster-dev)
	minikube profile $(cluster-dev)
	minikube addons enable ingress-dns

	helm upgrade --install --no-hooks --wait --timeout 600s registry-chart registry-chart/

initprod:
	minikube start -p $(cluster-prod) \
		--disk-size='10000mb' \
		--driver=hyperkit \
		--addons=ingress \
		--insecure-registry="local.dev:30007" \
		--memory 3072 \
		--dns-domain=$(dns-prod) --extra-config=kubelet.cluster-domain=$(dns-prod)

	kubectl config use-context $(cluster-prod)
	minikube profile $(cluster-prod)
	minikube addons enable ingress-dns

updatehost-dev:
	set -e ;\
	IP=$$(minikube ip) ;\
	sudo mkdir -p /etc/resolver ;\
	sudo rm -f /etc/resolver/$(cluster-dev)-$(dns-dev) ;\
	echo "domain $(dns-dev)" | sudo tee -a /etc/resolver/$(cluster-dev)-$(dns-dev)  > /dev/null ;\
	echo "nameserver $$IP" | sudo tee -a /etc/resolver/$(cluster-dev)-$(dns-dev)  > /dev/null ;\
	echo "search_order 1" | sudo tee -a /etc/resolver/$(cluster-dev)-$(dns-dev)  > /dev/null ;\
	echo "timeout 5" | sudo tee -a /etc/resolver/$(cluster-dev)-$(dns-dev)  > /dev/null ;\

updatehost-prod:
	set -e ;\
	IP=$$(minikube ip) ;\
	sudo mkdir -p /etc/resolver ;\
	sudo rm -f /etc/resolver/$(cluster-prod)-$(dns-prod) ;\
	echo "domain $(dns-prod)" | sudo tee -a /etc/resolver/$(cluster-prod)-$(dns-prod)  > /dev/null ;\
	echo "nameserver $$IP" | sudo tee -a /etc/resolver/$(cluster-prod)-$(dns-prod)  > /dev/null ;\
	echo "search_order 1" | sudo tee -a /etc/resolver/$(cluster-prod)-$(dns-prod)  > /dev/null ;\
	echo "timeout 5" | sudo tee -a /etc/resolver/$(cluster-prod)-$(dns-prod)  > /dev/null ;\

push:
	docker push $(image-name)

run-dev:
	kubectl delete secret helloworld-chart-auth || true && \
	kubectl create secret generic helloworld-chart-auth \
		--from-literal=MONGO_USERNAME=devuser \
		--from-literal=MONGO_PASSWORD=$(dev-password)
	helm upgrade --install -f helloworld-chart/values-dev.yaml --wait --timeout 600s helloworld-chart \
		--set mongodb.auth.username=devuser \
		--set mongodb.auth.password=$(dev-password) \
		--set mongodb.auth.database=hellodev helloworld-chart/

	kubectl get pods -A
	@echo "Result of curl command for nodejs-hello.local.dev:"
	curl -i --connect-timeout 30 --retry 10 --retry-delay 5 nodejs-hello.local.dev

run-prod:
	kubectl delete secret helloworld-chart-auth || true && \
	kubectl create secret generic helloworld-chart-auth \
		--from-literal=MONGO_USERNAME=produser \
		--from-literal=MONGO_PASSWORD=$(prod-password)
	helm upgrade --install -f helloworld-chart/values-prod.yaml --wait --timeout 600s helloworld-chart \
		--set mongodb.auth.username=produser \
		--set mongodb.auth.password=$(prod-password) \
		--set mongodb.auth.database=helloprod helloworld-chart/

	kubectl get pods -A
	@echo "Result of curl command for nodejs-hello.local.prod:"
	curl -i --connect-timeout 30 --retry 10 --retry-delay 5 nodejs-hello.local.prod
