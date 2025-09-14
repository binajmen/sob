mod client
mod server

default:
	@just --list

# Development - run locally with just
run:
	just client build-dev
	just server run

# Docker commands
docker-build:
	docker build -t sob-app .

docker-run: docker-build
	docker run --rm -it \
		-p 8000:8000 \
		--env-file .env \
		sob-app

# Docker Compose commands
up:
	docker compose up --build

down:
	docker compose down

logs:
	docker compose logs -f

restart:
	docker compose restart app

# Production build and run
prod-build:
	docker build -t sob-app:prod .

prod-run: prod-build
	docker run --rm -d \
		--name sob-app \
		-p 8000:8000 \
		--env-file .env.production \
		--restart unless-stopped \
		sob-app:prod

