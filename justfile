run:
	set working-directory := 'client'
	gleam run -m lustre/dev build --minify --outdir=../server/priv/static
	set working-directory := 'server'
	gleam run

