include "../circomlib/circuits/mimc.circom"
include "../circomlib/circuits/comparators.circom"

template AbsoluteDifference() {
    signal input in[2];
    signal output out;

    component lt = LessThan(32);
    lt.in[0] <== in[0];
    lt.in[1] <== in[1];
    var bit = 2*lt.out - 1;

    var diff = in[1] - in[0];
    out <== bit * diff;
}

template Main() {
    signal private input x1;
    signal private input y1;
    signal private input x2;
    signal private input y2;
    signal input distMax;

    signal output pub1;
    signal output pub2;

    component abs1 = AbsoluteDifference();
    component abs2 = AbsoluteDifference();

    abs1.in[0] <== x1;
    abs1.in[1] <== x2;
    abs2.in[0] <== y1;
    abs2.in[1] <== y2;

    component lt = LessThan(32);
    lt.in[0] <== abs1.out + abs2.out;
    lt.in[1] <== distMax + 1;

    lt.out === 1;

    component mimc1 = MiMC7(5);
    component mimc2 = MiMC7(5);

    mimc1.x_in <== x1;
    mimc1.k <== y1;
    mimc2.x_in <== x2;
    mimc2.k <== y2;

    pub1 <== mimc1.out;
    pub2 <== mimc2.out;
}

component main = Main();
