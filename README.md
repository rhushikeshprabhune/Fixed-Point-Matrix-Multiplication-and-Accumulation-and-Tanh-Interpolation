# G gate in LSTM cell
Hardware for a fixed-point multiplication which takes in 16-bit values of the variables was designed. Multiplication and accumulation is carried out which then proceeds to calculate the tanh values of the matrix multiplication outputs. The tanh of the matrix multiplication outputs is carried out through interpolation of tanh data stored in a ROM. If the output is greater than or less than a particular threshold, a constant value is considered since the tanh function saturates after a particular value. The graph of tanh is given below for reference. The design reads the matrix values from an SRAM and a ROM. The calculation starts when the busy flag is set high. The output values are stored in a SRAM after which the busy flag is set to low.
