include "../circomlib/circuits/mimc.circom"

template Main() {
    signal private input x1;
    signal private input y1;
    signal private input x2;
    signal private input y2;
    signal input distMax;

    signal output pub1;
    signal output pub2;

    var xMove = (x2>x1) ? x2-x1 : x1-x2;
    var yMove = (y2>y1) ? y2-y1 : y1-y2;
    var distValid = (xMove+yMove < distMax+1) ? 1 : 0;
    distValid === 1;

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
