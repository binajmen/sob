# Sing Out Brussels Voting Application

http://singout.brussels

Small application to organise a live voting session.

Support:

- [ ] Multiple sessions
- [ ] Proxy person
- [ ] tbd


docker compose -f docker-compose.yml up --build -d
cd client
gleam run -m lustre/dev build app --minify --outdir=../server/priv/static
cd server
dbmate migrate
gleam run -m squirrel
gleam run
