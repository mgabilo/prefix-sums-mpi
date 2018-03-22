# prefix-sums-mpi

This is a parallel program using MPI to calculate the [prefix sums](https://en.wikipedia.org/wiki/Prefix_sum) prefix sums for *N* double-precision numbers. 
This was just an academic exercise; MPI already has a
function to do this called MPI_Scan.

If there are *P* processes labeled as *0* to *P-1*, then each process
creates an array of *N/P* random numbers; all of the arrays are
treated as a single distributed array, such that process *0* contains
the first *N/P* numbers in the distributed array, process *1* contains
the next *N/P* numbers, and so on. I used the method of (1) creating a
perfect binary tree with *P* leaf nodes (processes) to compute the sum
of the *N* numbers, (2) and then used this tree to compute the prefix
sums of the *N* numbers. The numbers in the original distributed array
are then overwritten in-place with the prefix sums. The image below
shows the first part of the process.

![alt text](https://github.com/mgabilo/prefix-sums-mpi/blob/master/sum.png "prefix-sums-mpi execution phase I: computing the sums going up the tree")

To compute this initial sum tree, each process first generates its
*P/N* numbers and computes the sum.

Each node in the tree has a sum value associated with it, which is
equal to the sum of all of the array values associated with the leaves
of the subtree rooted at that node.  Execution begins at level 0 and
each iteration proceeds to the next higher level.  The nodes in each
level execute in parallel.  A node with label *r* that is in an
even-numbered position (positions begin at zero, not one) on level *l*
becomes a parent on level *l + 1*; its new sum is the sum of its
current sum and the sum of its sibling *r + 2^l*. A node with label
*r* in an odd-numbered position on the current level is responsible
for sending its sum to its future parent, its sibling *r - 2^l*; after
that, the node becomes inactive.  After *log_2(P)* levels have been
created, the node with rank 0 contains the sum.

Once this sum tree has been created, it will serve as input to the
prefix sum algorithm. This time, execution begins at level *log_2(P) -
1* inead of level 0, and each iteration proceeds to the next lower
level.  The nodes in each level execute in parallel.  Each node has a
"prefix sum" value associated with it, along with its "sum" value from
the first phase.  The prefix sum value of a node is defined as the sum
of all of the elements of the distributed array up to the subarray of
the rightmost leaf of that node.  Initially, since the root node
(level *log_2(P) - 1*) is holding the sum value of all elements of the
distributed array, its prefix sum value is set to this sum.  At each
level, the nodes on that level will get their prefix sums until
iteration stops at level 0.

A node that is a right child has its prefix sum set to the prefix sum
of its parent. A node that is a left child has its prefix sum set to
the prefix sum of its parent minus the sum of its right sibling.  Note
that a left child is its own parent, so the initial prefix sum it is
holding is that of its parent. This prefix sum is corrected by
subtracting away the sum of its right-sibling. This image below shows
how the left and right children acquire their prefix sums, given that
the prefix sum of their parent node has already been computed.

![alt text](https://github.com/mgabilo/prefix-sums-mpi/blob/master/partial.png "prefix-sums-mpi execution phase II: computing the prefix-sums going down the tree")


At the bottom level, each node *p'* of the *P* nodes will have a
prefix sum, which is the sum of all the elements in the distributed
array up to the last element of the subarray of *p'*. At this point,
each of the *P* nodes in parallel will sequentially compute their
remaining *N/P - 1* prefix sums, overwriting the original subarrays.


## Running the program

Install an MPI implementation; for example on Ubuntu 16.04 you can run
the following.

```
sudo apt-get install mpich libmpich-dev
```

To compile the program type "make" which compiles the program with
"mpicxx".

To run the program use "mpirun". For example, the following command
runs the program with 8 processors, where each processor generates
90000000/5 random double-precision floating point numbers in the range
[0.0, 50.0); the 6th prefix sum in the sequence is printed (position
5, indexed from 0).  The range of random numbers can be changed by
modifying the RAND_MAX_GEN in the source code. The program can also be
run without arguments and the default behavior is equivalent to these
given arguments.

```
mpirun -np 8 ./prefix 90000000 5
```

The output looks like the following.

```
Prefix sum number 5 is 117.719892
Took 0.436984 seconds
```


## License

This project is licensed under the MIT License (see the [LICENSE](LICENSE) file for details).

## Authors

* **Michael Gabilondo** - [mgabilo](https://github.com/mgabilo)

