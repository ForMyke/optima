.PHONY: start reset stop logs build
start:
reset:
stop:
	cd transportes-backend && docker compose down
logs:
	docker logs -f transportes_backend
