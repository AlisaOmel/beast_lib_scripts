# beast_lib_scripts

These scripts are used create a library that is used as a reference for FSL randomise skullstriping scripts (run-randomise.py).
The library can be created based on MINC (linear) or ANTS (non-linear) transformation. The MINC tends to create masks which are
too small while the non-linear ANTS tends to create masks that are too big.

The codes have been optimized to run each subject in parallel since they are independent of one another thus should be used with 
GNU Parallel.
