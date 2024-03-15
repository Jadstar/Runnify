import Toybox.StringUtil;
import Toybox.Cryptography;
import Toybox.System;
import Toybox.Math;
import Toybox.Application;

const VERIFIER_VALUES = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~";
const VERIFIER_LENGTH = 64;

function encodeString2Bytes(plain_text) {
    return StringUtil.convertEncodedString(plain_text, {
        :fromRepresentation => StringUtil.REPRESENTATION_STRING_PLAIN_TEXT,
        :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
        :encoding => StringUtil.CHAR_ENCODING_UTF8
    });
}

function sha256(byte_array) {
    var hash = new Cryptography.Hash({:algorithm => Cryptography.HASH_SHA256});
    hash.update(byte_array);
    return hash.digest();
}

function byteArray2String(byte_array) {
    return StringUtil.convertEncodedString(byte_array, {
        :fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
        :toRepresentation => StringUtil.REPRESENTATION_STRING_HEX,
        :encoding => StringUtil.CHAR_ENCODING_UTF8
    });
}

function base64encode(byte_array) {
    return StringUtil.convertEncodedString(byte_array, {
        :fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
        :toRepresentation => StringUtil.REPRESENTATION_STRING_BASE64,
        :encoding => StringUtil.CHAR_ENCODING_UTF8
    });
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
            var randomValidChar = possibleValues[Math.rand() % $.VERIFIER_LENGTH];
            codeVerifier[i] = randomValidChar;
        }
    }

    // Hash the bytes, encode and return
    var hashed = sha256(codeVerifier);
    return base64encode(hashed);
}