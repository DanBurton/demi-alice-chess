REACH = ./reach

./reach:
	curl https://raw.githubusercontent.com/reach-sh/reach-lang/master/reach -o ./reach ; chmod +x ./reach

.PHONY: run
run:
	$(REACH) run
