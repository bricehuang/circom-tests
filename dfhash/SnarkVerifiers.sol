pragma solidity ^0.5.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2)  internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas, 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas, 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas, 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract InitVerifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G2Point A;
        Pairing.G1Point B;
        Pairing.G2Point C;
        Pairing.G2Point gamma;
        Pairing.G1Point gammaBeta1;
        Pairing.G2Point gammaBeta2;
        Pairing.G2Point Z;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G1Point A_p;
        Pairing.G2Point B;
        Pairing.G1Point B_p;
        Pairing.G1Point C;
        Pairing.G1Point C_p;
        Pairing.G1Point K;
        Pairing.G1Point H;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.A = Pairing.G2Point([7633939327496231751969804728309375278450665097000523934120422420300253773679,9097476493094848647899528891386343016434872263547101225577536663322680179875], [326740143128414351822993778215369481816691707016873597559428267652590156111,13827983829256514187282296433407175830387662364847635092395598308123617034387]);
        vk.B = Pairing.G1Point(14528699399984902887667446805402361840980236228334308145927431981649993702163,5601083558758147014379090448875249062998283300293385524700242236369562120633);
        vk.C = Pairing.G2Point([5965654843073541245926191468035173152217885460052139045153321639964160214054,1149222068950824249913241534858130370884569190209008866586929909674117726791], [9385360877391933164705760762495480441765779723813467732281476374459410679835,1589255979824815549814271379506306918887730258475869435044030105106986051727]);
        vk.gamma = Pairing.G2Point([5216725022989090791893104306546098690349167981418345906214945694781908911594,19596408729353374006980649402106683161043372260704526440263038413949319026845], [12973786366686505300350039381498669387177026178131054012041307996568576074381,21045515368144700873616165243275880423379110688162732671986786704533437309756]);
        vk.gammaBeta1 = Pairing.G1Point(15770682291722414792106470561827939126136817170380206178382112746692203369815,15004170013779276034034412209540942591913249380407001961559636160116577698525);
        vk.gammaBeta2 = Pairing.G2Point([11376220377236984874038334142154397844585863860654449281539246684590071766312,8974945450168568508057731343688095935940866297622191895253961637218780016912], [8104767677991937725257163340693601613099973480742257571780201524674775381959,13851676614126207550042051764686725638178636836403476848305664593405866282090]);
        vk.Z = Pairing.G2Point([18771527096077858049577658200287484085029744706271099388274459768753841576473,6570133195520925955871287859432554575876518876710538039071235502323955575680], [2633381142959644861028529948993962589707753957564966363644196821023859952952,14993717193573785038405695934033315150513609727421411851420940422195401476559]);
        vk.IC = new Pairing.G1Point[](2);
        vk.IC[0] = Pairing.G1Point(15497912279680506951215798591581054902241589952592752025201592493899778650490,7501197682430745319982247476574486728678564683727903675765456235665258449887);
        vk.IC[1] = Pairing.G1Point(17076597725194102707835050304642114950623394808257444029228455423647092360184,10124890093200955214044859900119033773651650784508353914080194280045518520921);

    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd2(proof.A, vk.A, Pairing.negate(proof.A_p), Pairing.P2())) return 1;
        if (!Pairing.pairingProd2(vk.B, proof.B, Pairing.negate(proof.B_p), Pairing.P2())) return 2;
        if (!Pairing.pairingProd2(proof.C, vk.C, Pairing.negate(proof.C_p), Pairing.P2())) return 3;
        if (!Pairing.pairingProd3(
            proof.K, vk.gamma,
            Pairing.negate(Pairing.addition(vk_x, Pairing.addition(proof.A, proof.C))), vk.gammaBeta2,
            Pairing.negate(vk.gammaBeta1), proof.B
        )) return 4;
        if (!Pairing.pairingProd3(
                Pairing.addition(vk_x, proof.A), proof.B,
                Pairing.negate(proof.H), vk.Z,
                Pairing.negate(proof.C), Pairing.P2()
        )) return 5;
        return 0;
    }
    function verifyInitProof(
            uint[2] memory a,
            uint[2] memory a_p,
            uint[2][2] memory b,
            uint[2] memory b_p,
            uint[2] memory c,
            uint[2] memory c_p,
            uint[2] memory h,
            uint[2] memory k,
            uint[1] memory input
        ) view public returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.A_p = Pairing.G1Point(a_p[0], a_p[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.B_p = Pairing.G1Point(b_p[0], b_p[1]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        proof.C_p = Pairing.G1Point(c_p[0], c_p[1]);
        proof.H = Pairing.G1Point(h[0], h[1]);
        proof.K = Pairing.G1Point(k[0], k[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
contract MoveVerifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G2Point A;
        Pairing.G1Point B;
        Pairing.G2Point C;
        Pairing.G2Point gamma;
        Pairing.G1Point gammaBeta1;
        Pairing.G2Point gammaBeta2;
        Pairing.G2Point Z;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G1Point A_p;
        Pairing.G2Point B;
        Pairing.G1Point B_p;
        Pairing.G1Point C;
        Pairing.G1Point C_p;
        Pairing.G1Point K;
        Pairing.G1Point H;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.A = Pairing.G2Point([19846879431091076714900301876556787265930823917260651975963118946100479418888,9929149339156568542196190931443718301580858314678464389009110388868360900836], [18015273282877676487088176298923347527830881477015981149657897601677746218406,8471250708335198915453117247624392926185013041226344738747845860471482108644]);
        vk.B = Pairing.G1Point(9777797935796539567685518024089718380151926865641709264090275856130010131964,20218032573159282059507950768953510648063514876471256946239373677439593239152);
        vk.C = Pairing.G2Point([13325074305382856148962576493492200991311882583365487044279488632597338343818,2240614322169380055852441287254438809984030223096430955398558742094260474741], [967125384261535690983968574033904287682773939322273728077525432287212912808,14455035435264562609025781838774591713410719998919522400854155105769046355161]);
        vk.gamma = Pairing.G2Point([4635040756466575122689391766213868643973368999292737835507128787374912322952,21540826891329547388717966056158533105473209104231372268079255302771357369786], [2560739079217427171761931892599944161272375997439895716963106061530507657440,11702029726317290941893172234238946992746945331497020777186920379918895812418]);
        vk.gammaBeta1 = Pairing.G1Point(14359728747563973172963094508599279505059921186705043341632592368248308001220,16999137618942824862549255823322235681368139321782051551027969950430799271848);
        vk.gammaBeta2 = Pairing.G2Point([1089523011816951896086460738326127860493213829626848422819862967749861036856,19364689771518236527896987347022040246294759925952194468993376651512112371232], [2720660241609196202492091739772523957179303547953569476835360245614856932996,5871617000568437740594359053486615007092024546591810573053349605501753395944]);
        vk.Z = Pairing.G2Point([11596293380719048103401882942663382130047011251728312663618964341742926439325,968409202036164399384313377798448255263521326254993448997474346488026549192], [19033782007785164437963304171032727946290197606939725875378140168107550341819,15727413835215253771595704825524984946528501315963839133334575979115027042942]);
        vk.IC = new Pairing.G1Point[](4);
        vk.IC[0] = Pairing.G1Point(20669513079864447577918024627574320731936812239546372069286048329908391142628,17442511695219732045644921633005310845696745771570684188313516976485141926066);
        vk.IC[1] = Pairing.G1Point(11574576078955100783728692031212106872383813213721456975322212503574137751624,17158687642988400501424323712766474170591362109403634372279868717824014848357);
        vk.IC[2] = Pairing.G1Point(9114732226959498753838935994089847625301746938612543470543317350331820975057,11349744799249655457520200445177999029250497175856611998816471111931663266908);
        vk.IC[3] = Pairing.G1Point(7689652757129668101070653538453000013004444254818647937813132603854686100288,16911925621863975779564762276957356881503305455177884395736117045464313704700);

    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd2(proof.A, vk.A, Pairing.negate(proof.A_p), Pairing.P2())) return 1;
        if (!Pairing.pairingProd2(vk.B, proof.B, Pairing.negate(proof.B_p), Pairing.P2())) return 2;
        if (!Pairing.pairingProd2(proof.C, vk.C, Pairing.negate(proof.C_p), Pairing.P2())) return 3;
        if (!Pairing.pairingProd3(
            proof.K, vk.gamma,
            Pairing.negate(Pairing.addition(vk_x, Pairing.addition(proof.A, proof.C))), vk.gammaBeta2,
            Pairing.negate(vk.gammaBeta1), proof.B
        )) return 4;
        if (!Pairing.pairingProd3(
                Pairing.addition(vk_x, proof.A), proof.B,
                Pairing.negate(proof.H), vk.Z,
                Pairing.negate(proof.C), Pairing.P2()
        )) return 5;
        return 0;
    }
    function verifyMoveProof(
            uint[2] memory a,
            uint[2] memory a_p,
            uint[2][2] memory b,
            uint[2] memory b_p,
            uint[2] memory c,
            uint[2] memory c_p,
            uint[2] memory h,
            uint[2] memory k,
            uint[3] memory input
        ) view public returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.A_p = Pairing.G1Point(a_p[0], a_p[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.B_p = Pairing.G1Point(b_p[0], b_p[1]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        proof.C_p = Pairing.G1Point(c_p[0], c_p[1]);
        proof.H = Pairing.G1Point(h[0], h[1]);
        proof.K = Pairing.G1Point(k[0], k[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
