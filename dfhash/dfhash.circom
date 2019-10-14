include "../circomlib/circuits/mimcsponge.circom"
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

    /*
        220 = 2 * ceil(log_5 p), as specified by mimc paper, where
        p = 21888242871839275222246405745257275088548364400416034343698204186575808495617
    */
    component mimc1 = MiMCSponge(2, 220, 1);
    component mimc2 = MiMCSponge(2, 220, 1);

    mimc1.ins[0] <== x1;
    mimc1.ins[1] <== y1;
    mimc1.k <== 0;
    mimc2.ins[0] <== x2;
    mimc2.ins[1] <== y2;
    mimc2.k <== 0;

    pub1 <== mimc1.outs[0];
    pub2 <== mimc2.outs[0];
}

component main = Main();
