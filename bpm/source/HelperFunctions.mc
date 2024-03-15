import Toybox.StringUtil;
import Toybox.Cryptography;
import Toybox.System;
import Toybox.Math;
import Toybox.Application;
import Toybox.Lang;

const VERIFIER_VALUES = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
const VERIFIER_LENGTH = 64;

function sha256(byte_array) {
    var hash = new Cryptography.Hash({:algorithm => Cryptography.HASH_SHA256});
    hash.update(byte_array);
    return hash.digest();
}

function byteArray2String(byte_array) {
    return StringUtil.convertEncodedString(byte_array, {
        :fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
        :toRepresentation => StringUtil.REPRESENTATION_STRING_PLAIN_TEXT,
        :encoding => StringUtil.CHAR_ENCODING_UTF8
    });
}

function base64encode(byte_array) {
    var base64 = StringUtil.convertEncodedString(byte_array, {
        :fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
        :toRepresentation => StringUtil.REPRESENTATION_STRING_BASE64,
        :encoding => StringUtil.CHAR_ENCODING_UTF8
    });

    return base64;
}

function getCodeChallenge(codeVerifier) {

    // Replace any characters that arent in the PCKE standard
    var possibleValues = $.VERIFIER_VALUES.toUtf8Array();
    for (var i = 0; i < $.VERIFIER_LENGTH; i++) {
        // Check possible value array
        var charInPossibleValues = false;
        for (var j = 0; j < $.VERIFIER_VALUES.length(); j++) {
            if (codeVerifier[i] == possibleValues[j]) {
                charInPossibleValues = true;
            }
        }

        // Set bad char to good char
        if (!charInPossibleValues) {
            var randIndex = Math.rand() % $.VERIFIER_VALUES.length();
            var randomValidChar = possibleValues[randIndex];
            codeVerifier[i] = randomValidChar;
        }
    }

    // Hash the bytes, encode and return
    var hashed = sha256(codeVerifier);
    var codeChallenge = base64encode(hashed);
    System.println("Code Challenge: " + codeChallenge);
    System.println("Code Verifier: " + codeVerifier);
    System.println("Converted Verifier: " + byteArray2String(codeVerifier));
    return codeChallenge;
}