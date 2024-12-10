all: build run

build:
	as -g find_name.s -o find_name.o
	ld find_name.o -o find_name

run:
	./find_name

clean:
	rm find_name.o find_name
