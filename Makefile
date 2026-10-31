.PHONY: up down clean

up:
	docker compose up --build

down:
	docker compose down

clean:
	docker compose down --rmi local
	rm -rf secrets
