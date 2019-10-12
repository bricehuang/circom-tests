include "../circomlib/circuits/mimc.circom"

template Main() {
    signal private input x1;
    signal private input x2;

    signal output xMove;

    var shouldBeXmove = x2-x1;
    if (x1 > x2) {
        shouldBeXmove = x1-x2;
    }

    xMove <== shouldBeXmove;
}

component main = Main();
