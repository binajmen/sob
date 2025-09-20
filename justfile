mod client
mod server

default:
	@just --list

dev:
	docker compose -f docker-compose.dev.yml up --build -d
	just client build
	just server run
dev-watch:
	watchexec \
		--restart \
		--verbose \
		--wrap-process=session \
		--stop-signal SIGTERM \
		--exts gleam \
		--debounce 500ms \
		--watch server/src/ \
		--watch client/src/ \
		--watch shared/src/ \
		--ignore '**/build/**' \
		--ignore '**/target/**' \
		--ignore '**/sql.gleam' \
		-- "just dev"

# Docker commands
dev-docker:
	watchexec --restart --verbose --exts gleam --debounce 500ms --watch server/src/ --watch client/src/ --watch shared/src/ -- "docker compose up --build -d app"

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

