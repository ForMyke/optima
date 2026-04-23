.PHONY: start reset stop logs

start:
	./dev-start.sh

reset:
	./dev-start.sh --reset

stop:
	cd transportes-backend && docker compose down

logs:
	docker logs -f transportes_backend
