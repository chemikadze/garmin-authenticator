module Crypto {

    class InvalidDataFormatException extends Toybox.Lang.Exception {
    }

    function base32decode(s) {
        var blockCount = s.length() / 8;
        if (s.length() % 8 != 0) {
            blockCount = blockCount + 1;
        }
        var lastBlock = decode32block(s.substring((blockCount - 1) * 8, blockCount * 8));
        var result = new[(blockCount - 1) * 5 + lastBlock.size()];
        for (var i = 0; i < blockCount - 1; ++i) {
            var block = decode32block(s.substring(i * 8, (i + 1) * 8));
            for (var j = 0; j < block.size(); ++j) {
                result[i * 5 + j] = block[j];
            }
        }
        for (var j = 0; j < lastBlock.size(); ++j) {
            result[(blockCount - 1) * 5 + j] = lastBlock[j];
        }
        return result;
    }

    function decode32block(block) {
        var result = [ 0, 0, 0, 0, 0 ];
        var blockLength = 0;
        for (var i = 0; i < block.length(); ++i) {
            var symbol = block.substring(i, i + 1);
            var bits = decode32digit(symbol);
            if (bits == -1) {
                if (symbol.find("=") != 0) {
                    throw new InvalidDataFormatException();
                } else {
                    break;
                }
            }
            var index = i * 5 / 8;
            var offset = i * 5 % 8;
            var currentSignificantBits = min(8 - offset, 5);
            var nextSignificantBits = 5 - currentSignificantBits;
            result[index] = result[index] + (bits >> nextSignificantBits) << (8 - currentSignificantBits - offset);
            if (nextSignificantBits != 0) {
                result[index + 1] = result[index + 1] + (bits % (1 << nextSignificantBits)) << (8 - nextSignificantBits);
            }
            blockLength = index + 1;
        }
        if (blockLength == 5) {
            return result;
        } else {
            var cutResult = new[blockLength];
            for (var i = 0; i < blockLength; ++i) {
                cutResult[i] = result[i];
            }
            return cutResult;
        }
    }

    function min(a, b) {
        if (a < b) { return a; }
        else { return b; }
    }

    function max(a, b) {
        if (a > b) { return a; }
        else { return b; }
    }

    hidden var patterns = [
        ["ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0],
        ["abcdefghijklmnopqrstuvwxyz", 0],
        ["234567", 26]
    ];

    function decode32digit(symbol) {
        for (var i = 0; i < 3; ++i) {
            var r = patterns[i][0].find(symbol);
            if (r != null) {
                return r + patterns[i][1];
            }
        }
        return -1;
    }

    function sha1(data) {
        return [0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2];
    }

    class TOTP {

        var decodedKey, // K
            epoch = 0, // T0
            interval = 30, // TI
            tokenLength = 6; // N

        function initialize(key) {
            decodedKey = base32decode(key);
        }

        function generateToken() {
            var c = (Time.now().value() - epoch) / interval;
            // Compute the HMAC hash H with C as the message and K as the key
            // (the HMAC algorithm is defined in the previous section, but also most cryptographical libraries support it).
            // K should be passed as it is, C should be passed as a raw 64-bit unsigned integer.
            var h = sha1(new[0]);
            var o = h[19] % 16; // 4 least significant bits
            // Take 4 bytes from H starting at O bytes MSB, discard the most significant bit and store the rest as an (unsigned) 32-bit integer, I.
            var tokenNumber = 0l;
            for (var i = 0; i < 4; ++i) {
                tokenNumber = tokenNumber + (h[o + 3 - i] << (i * 8l));
            }
            // The token is the lowest N digits of I in base 10. If the result has fewer digits than N, pad it with zeroes from the left.
            var format = "%0" + tokenLength + "i";
            var token = tokenNumber.format(format);
            if (token.length() > tokenLength) {
                return token.substring(token.length() - tokenLength, token.length());
            } else {
                return token;
            }
        }
    }

}