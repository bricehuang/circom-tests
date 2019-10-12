Contents:

* factor: circuit verifying "I know ints a,b such that a*b=c"

* bitify: circuit verifying "I know an int with this binary representation out"

* bitadd: circuit verifying "I know ints a,b such that a+b=out mod 2^32"

* sha: circuit verifying "I know ints x,y such that sha256(x,y)=out"

* dfHash: circuit attempting to verify "I know ints (x1,y1,x2,y2) such that mimc(x1,y1)=pub1, mimc(x2,y2)=pub2, and |x1-x2|+|y1-y2|<=distMax"

note that sha/circuit.json, sha/proving_key.json, sha/verification_key.json are gitignored because they're enormous.
```
cd sha/
circom sha.circom
snarkjs setup
```
to rebuild.

