all:
	ruby setup/mkenv.rb

init:
	make -C plato-ui init

clean:
	make -C plato-ui clean

