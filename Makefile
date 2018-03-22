all: prefix

prefix: prefix.cpp
	mpicxx -lm -Wall -O3 prefix.cpp -o prefix

clean:
	rm -f prefix
