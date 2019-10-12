Contents:
This is an attempt at a circuit verifying "I know (x1,y1,x2,y2) such that mimc(x1,y1)=pub1, mimc(x2,y2)=pub2, and |x1-x2|+|y1-y2|<=distMax."

Unfortunately comparisons on signals don't semm to work in snarks.

* incorrect.circom is a non-working circuit attempting to verify the statement above.

* noDistCheck.circom is a working circuit verifying "I know (x1,y1,x2,y2) such that mimc(x1,y1)=pub1 and mimc(x2,y2)=pub2."

* minBuggyExample is a non-working circuit isolating the bug to a comparison not working.

The remaining files in this repo are for noDistCheck.circom.
