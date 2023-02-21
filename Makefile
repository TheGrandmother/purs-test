.PHONY: css
css:
	npx sass src/style.scss style.css

.PHONY: server
serve:
	npx live-server --port=8888 --watch=index.html,index.js,style.css
