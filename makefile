all:
	stack exec site clean
	stack exec site build
	git commit -am "hakyll update"
	git push
