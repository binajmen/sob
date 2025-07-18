mod client
mod server

default:
	@just --list

run:
	just client build-dev
	just server run
