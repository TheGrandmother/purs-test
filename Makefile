package-lock.json: package.json
	npm i

style.css: src/style.scss
	npx sass src/style.scss style.css

.PHONY: server
serve:
	npx live-server --port=8888 --watch=index.html,index.js,style.css --no-browser --cors

.PHONY: watch
watch: package-lock.json style.css
	npx spago bundle-app --watch
