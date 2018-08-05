//    MIT License
//
//    Copyright (c) 2018 Veldspar Team
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import Foundation
import CryptoSwift

/*
 *      The Economy class will take tokens and verify their value, based on the complexity of the workload used to produce it.
 */

public class Economy {
    
    // pattern values - the value assigned given the chance of matching the pattern
    // token hash ff7a6c6b53c2e2a would have a value of 0
    // token hash ffff7a6c6b53c2e2 would have a value of 1
    // token hash ffffff7a6c6b53c2e would have a value of 10
    // etc.....
    
    static let patternByte = UInt8(255)
    
    // sequential match value - additional value for all the subsequent sequential hashes which start with the patternByte
    static let iterationMatch: [Int /* active block height */: [AlgorithmType : [Int]]] =
        [
            0 : [AlgorithmType.SHA512_Append :
                [0,0,0,0,100,500,1000,2000,5000,5000,5000,5000,5000,5000]
            ]
    ]
    
    // match reward bytes - number of bytes (minus pattern matched) to attribute value for
    static let occurrencesRewardBytes = 24
    
    // match reward matrix - value awarded for number of additional bytes up to `occurrencesRewardBytes`
    static let occurrencesRewardMatrix : [Int /* active block height */: [AlgorithmType : [Int]]] =
        [
            0 : [AlgorithmType.SHA512_Append :
                [0,0,0,0,50,100,500,1000,2000,5000,5000,5000,5000,5000,5000]
            ]
    ]
    
    // match reward matrix - value awarded for number of additional bytes up to `occurrencesRewardBytes`
    static let pairsRewardMatrix : [Int /* active block height */ : [AlgorithmType : [Int]]] =
        [
            0 : [AlgorithmType.SHA512_Append :
                [0,0,0,5,10,20,50,100,500,1000,1000,1000,1000,1000,1000,1000]
            ]
    ]
    
    // the 'magic beans' table, is an assortment of random sequences which have value.  This stops the programatic discovery of only small value tokens.  Which would result in transactions which are far too numberous (e.g. sending 1000 veldspar would result in 10,000 token re-allocations)
    static let magicBeans : [Int /* active block height */ : [AlgorithmType : [String:Int]]] =
        [
            0 : [AlgorithmType.SHA512_Append :
                ["ade532": 500, "36266e": 2, "144766": 1000, "97bb67": 1, "07eb5b": 5, "b2249e": 5, "86bcb0": 10, "7e6d27": 2000, "49ed31": 1000, "55319d": 1, "7c0410": 2000, "059483": 5, "2dc3a4": 2, "bdc669": 100, "5dcd32": 1000, "9514a8": 1000, "c64e03": 500, "0e2050": 2, "c6b0bb": 1000, "480306": 5, "ab898d": 10, "616168": 1, "1ed587": 10, "3d1590": 500, "7e8570": 5, "88ee3a": 50, "ad140b": 2, "507cd7": 500, "4c2cd0": 1, "259e12": 10, "142a06": 10, "c2c570": 1, "771517": 10, "315be6": 10, "1cda05": 50, "8c22d2": 2, "193b35": 1, "776301": 5, "49ad1a": 50, "e2c203": 5, "dbb0b1": 1000, "429b3d": 100, "419d62": 100, "9eda2a": 50, "db7d2a": 10, "c400c9": 2000, "e76598": 10, "30a684": 2000, "532904": 100, "e01cdd": 1, "a2db7c": 10, "22950d": 50, "ea1b8a": 500, "872e4a": 5, "415bce": 100, "4d82b0": 100, "809d85": 10, "0b3d10": 1000, "3bd38c": 1000, "61edaa": 5, "617bea": 2000, "e306d2": 50, "b1aee1": 2, "1147ec": 50, "b5a0a8": 1, "4ba210": 1000, "522db1": 2, "d144e3": 1, "575030": 100, "942d79": 100, "19844e": 50, "ab0219": 2, "0d0ae8": 2, "06429e": 5, "5a70ca": 100, "10b041": 1, "d29934": 100, "17c063": 2, "77469c": 1000, "97e61e": 2000, "a93097": 500, "c384ad": 2, "d1a2d9": 500, "56e998": 100, "958ba6": 5, "041294": 100, "1d99c8": 1, "c3ac52": 2000, "8374e6": 2, "bdd969": 500, "87bc42": 2, "8cd2dd": 10, "30045b": 1, "0d5876": 100, "6c63e2": 50, "0ccadb": 100, "179807": 50, "2d9b2b": 2000, "e4caea": 1, "b0e35a": 1000, "364c1a": 1000, "896911": 5, "30511c": 1, "b89120": 2, "35bdca": 2000, "8c66a4": 2, "0d7006": 50, "da39d4": 500, "82d7cb": 2, "9c8d21": 2000, "3c54a9": 5, "555970": 1, "e7a784": 100, "c67d14": 5, "8e0853": 100, "eebd22": 50, "9eb7c9": 2000, "b3c7de": 2000, "8841be": 5, "29c046": 5, "7d3106": 100, "cc2c44": 2, "33e1b0": 5, "5e74e1": 10, "57bcb8": 5, "66a149": 1000, "500452": 500, "b6e053": 500, "c64bb5": 100, "ab4d9a": 2000, "509cac": 2, "7c36de": 5, "4a9422": 1, "889165": 5, "560aa4": 500, "dd5d4a": 100, "86578b": 500, "3ca606": 100, "51d999": 1, "9c0014": 2, "923104": 2000, "d95656": 500, "ba01cd": 500, "9a0e67": 50, "e2b131": 500, "3b5db3": 10, "ca3211": 10, "a2be3b": 50, "35a942": 5, "6c8977": 5, "9b639c": 100, "98b200": 1000, "0419ba": 100, "c19ccc": 100, "ab474c": 2000, "77c390": 2, "d65237": 100, "7d026b": 10, "d58dc5": 5, "45b982": 10, "03ca52": 1, "25023a": 50, "474368": 500, "9a1b18": 10, "7205dd": 2000, "957221": 100, "a909ac": 2, "5b826b": 10, "ace7d7": 2000, "b4822d": 1, "b430e2": 5, "8e6b6d": 100, "d91e9d": 2, "a86bb7": 500, "1e7773": 10, "d179ac": 1, "d41070": 2, "4b6407": 50, "c28c3a": 50, "2ee092": 2000, "111976": 5, "3e8d1a": 50, "166a09": 1, "63b838": 1, "3d8949": 2, "b92342": 2000, "c05d5d": 1, "e4707d": 5, "480b12": 2000, "18e443": 10, "6497d4": 2000, "a4c654": 10, "8d8563": 1, "c64577": 5, "5cd1be": 1, "5646a8": 2000, "842e92": 500, "dd051d": 5, "a7d593": 1, "dd009d": 2000, "9d5cc0": 2000, "27356e": 2000, "db4c65": 1000, "c0b45b": 1, "67b62d": 100, "1a503d": 100, "e791e0": 50, "3c0aa4": 50, "3408e9": 5, "3bdeca": 500, "5c66c6": 2, "2ee2ab": 1, "82b78b": 100, "203071": 50, "16e7e9": 10, "0934b1": 5, "c9c781": 1000, "67792a": 5, "dc7dd6": 2000, "4e8805": 1000, "a165b7": 100, "07e693": 100, "0d5bed": 50, "87ad3e": 1, "39a131": 50, "d21540": 10, "c69613": 100, "3c491e": 2, "c1d2a7": 1, "bedc31": 5, "6c8d81": 500, "ab8d53": 1, "813bcb": 500, "008cdb": 2000, "bc5b82": 2000, "3b8a23": 10, "8bee5b": 10, "4b7231": 1, "dc790e": 100, "a6a00c": 500, "37bdc1": 500, "4c6c9d": 10, "e0448d": 50, "50a2c7": 1, "a14cdb": 10, "4360e0": 1000, "ac864e": 100, "7d2c80": 500, "9c6622": 1, "0580e9": 1000, "7b54d6": 2, "9a2353": 2000, "e895e2": 5, "804b0b": 2000, "55a2a5": 1000, "ab953a": 2000, "a9db27": 1, "3eb7c6": 10, "74177b": 10, "87274a": 100, "b6ca05": 50, "5ec1ce": 10, "ee09e3": 10, "01b73d": 5, "3eb868": 5, "b214d5": 2000, "6db159": 1000, "a3a2c6": 50, "8130d6": 1000, "6b4269": 1, "750bd5": 500, "0edce5": 1, "868ee5": 1000, "9a9c9a": 5, "4dea21": 10, "ce22d2": 2, "552c61": 1, "3d6181": 2000, "5024e8": 1, "ba8b66": 2, "3a8857": 500, "0c016c": 5, "3990c9": 50, "46dd83": 2000, "1b9323": 50, "072661": 50, "b0e049": 1, "31db94": 100, "75817b": 1000, "ac2e35": 2000, "49a170": 500, "0d3d46": 50, "33c47a": 500, "8d8d96": 1000, "43a0ad": 50, "247b5e": 2000, "ba3050": 10, "ec14c9": 1000, "5ccc05": 1, "195bab": 500, "e8459b": 1, "b14554": 50, "c24607": 1000, "907e74": 1000, "52402e": 10, "40375d": 500, "549460": 5, "964e95": 2000, "495e6b": 100, "6c3c64": 2000, "661261": 5, "6b7401": 100, "248d6a": 1, "599ee1": 10, "b9a01e": 2, "58418c": 2, "ed8c99": 50, "6ed039": 1000, "014b27": 1000, "7450be": 50, "e83b1b": 1, "052308": 10, "444547": 1, "a4d4d2": 1, "9eebd6": 2, "8dd63b": 1, "6a575d": 100, "d6574d": 2000, "7017ea": 10, "189dd3": 1, "98e63b": 2000, "07c01b": 50, "07267b": 1, "388524": 1, "3dae85": 5, "470e42": 2, "c7d82a": 2000, "1b291b": 2, "ae1e83": 100, "9bee2b": 1000, "174cd2": 1000, "bcc1e3": 10, "b85b30": 5, "6c34dd": 1000, "877574": 500, "38d191": 5, "790b93": 10, "d4c66c": 500, "24edc8": 1000, "7dd540": 100, "746c2b": 1, "897dd5": 2, "e91073": 50, "96eb52": 1000, "e0cbb8": 10, "3a4307": 500, "6bbaa9": 100, "16285c": 100, "aa784b": 500, "1167a6": 100, "31b23a": 500, "62c973": 2000, "231d13": 1, "425ea5": 5, "e89162": 1, "630a31": 10, "466b28": 50, "300dd5": 50, "8b121a": 1, "821d29": 10, "b2a251": 500, "e06126": 2000, "4da589": 50, "7135aa": 5, "ac9227": 500, "0d7c4c": 1000, "45a702": 5, "db03aa": 100, "460adc": 10, "36524d": 500, "a2d4cc": 1000, "90005d": 1, "a299c2": 50, "a31cd0": 500, "cee1e3": 100, "2d7da2": 1, "428183": 10, "9ad8b7": 1, "bae587": 50, "0d80d3": 500, "a242a7": 10, "8d172b": 500, "925874": 5, "552473": 100, "0779c9": 1000, "d9be89": 100, "37b860": 1000, "76c091": 10, "bba91e": 2, "6468a5": 5, "8046c4": 2, "1b6811": 1, "627591": 100, "5b5b02": 1, "cb9217": 50, "d207a4": 500, "072e93": 50, "b94d27": 1000, "4da2e3": 1, "3b6bb3": 50, "a03be6": 500, "e0c73a": 2000, "3d2d5d": 2, "e49dad": 10, "d153c5": 500, "2cbdad": 10, "ece50c": 1, "2a7ec0": 100, "9e0507": 2000, "30aeee": 1000, "9b36c2": 1000, "35e30c": 5, "c398eb": 1, "377131": 1, "4720a5": 2000, "a9bc32": 2000, "d26148": 1000, "bbb60b": 2, "c7a1cc": 100, "5d43bc": 500, "6297c4": 2, "c44c8a": 10, "6d861c": 2, "5ed944": 100, "e5cd92": 1, "8b907c": 50, "8aa7aa": 1000, "409832": 100, "60299a": 50, "60be93": 2, "6b8494": 50, "105edc": 500, "621ac1": 1000, "b56ab0": 1, "6b9d8c": 5, "718b37": 100, "5b6b83": 500, "ccc489": 5, "e40cae": 10, "996492": 100, "3a7ebd": 100, "d9e87b": 1000, "222bae": 1, "d25a81": 5, "65a7d9": 10, "da7b9e": 10, "89289d": 2000, "06dc2c": 2000, "7696b8": 5, "211d2a": 10, "06deee": 2, "ab5e84": 2000, "7e209d": 5, "9e3325": 5, "8640a1": 1000, "1c454e": 100, "0d75ae": 5, "d93b32": 1, "38bce2": 2000, "2e1c0c": 50, "4bc742": 500, "ddd5aa": 50, "50e0c5": 500, "ed717d": 1000, "212b99": 2000, "937ce4": 2000, "967bc9": 100, "ece250": 500, "37ce1a": 500, "3dc2d3": 5, "3672c2": 2, "0b4221": 5, "ea4a09": 2000, "c5db07": 1000, "4c5973": 100, "e14396": 2000, "7e422e": 1, "11120c": 100, "7ca754": 50, "0d1e1b": 1, "d6d8c0": 2, "127c77": 50, "daccb3": 10, "4b9106": 500, "4d43e4": 10, "e35703": 10, "18822b": 2000, "cde269": 10, "d9a4d6": 1000, "e87012": 2, "b4a388": 1, "8a6cad": 50, "33242c": 50, "b034b1": 2, "506dbb": 1, "c7d861": 500, "c13a52": 2000, "d97c9c": 2000, "882397": 10, "16985a": 1, "5ac94e": 2, "198200": 1000, "acccb0": 1, "72d258": 10, "1d2745": 50, "4de849": 2, "122499": 100, "2a6c58": 50, "6c0791": 10, "040ba1": 1000, "aba13d": 100, "5bbd49": 2000, "e397c9": 50, "324d8e": 2000, "5b63d1": 5, "7a43cb": 10, "461d16": 100, "be1473": 1, "256c86": 1, "3134c0": 100, "5921c5": 5, "70c89b": 10, "caeb80": 2, "d98d40": 2000, "6d8641": 10, "33b723": 500, "106dee": 1000, "e1a491": 500, "327605": 1, "2e2caa": 500, "d03e43": 1000, "ed44c8": 10, "3419d0": 10, "9cd316": 10, "24ba0e": 10, "a4cd4a": 500, "8861ca": 100, "d66157": 100, "57b6eb": 1, "35d3bb": 1, "6ae004": 1000, "3dc2da": 1, "252a4c": 2, "732b0a": 500, "3ae621": 2000, "b1e48d": 100, "19c678": 2, "be3841": 2000, "3e967a": 5, "a5214d": 1000, "ac723a": 50, "8e6807": 500, "a981c4": 2000, "8634c1": 50, "4c3a73": 100, "d9caa1": 500, "e9accc": 1, "4619d1": 50, "de8224": 50, "ceba52": 1, "449e75": 1, "b9d64c": 2, "6b5142": 2000, "aa0cd0": 2000, "5c38e7": 100, "064d8d": 5, "e110ad": 100, "339008": 2000, "4c591c": 100, "34b4d9": 50, "c7d5d5": 5, "b79db5": 2, "c12364": 2000, "824180": 1, "d06354": 5, "85358b": 1000, "7ece25": 1, "3be9c1": 2000, "4e8e81": 100, "b5ad4d": 50, "39694d": 1000, "675ed5": 5, "05cedd": 2, "6d1a86": 1, "a11641": 5, "775e4c": 5, "568a7d": 5, "b2ad7b": 500, "2e5886": 100, "ede40d": 50, "75c880": 1000, "6e0b65": 5, "6ae998": 50, "cd3226": 100, "d13d0c": 100, "04c437": 1, "d23a68": 1000, "3dbb7c": 5, "b30827": 2000, "710a44": 2000, "b8c32e": 500, "82b0b9": 1000, "83de50": 50, "acd7ea": 500, "137243": 5, "c6c391": 50, "02a442": 2000, "09b84e": 500, "5aba87": 100, "75e7cd": 1, "2c0649": 2, "c82b8d": 5, "013db3": 2, "7e36de": 2000, "44639a": 1000, "ec90a2": 2, "4bc342": 2, "78ad1d": 1000, "917145": 100, "b4e804": 1000, "3e1558": 500, "9d40c0": 1, "7bb79e": 50, "ee2c89": 2, "c0580d": 500, "ce340c": 2, "d2d05c": 50, "b9d30b": 2000, "182070": 5, "9d4172": 2, "703547": 50, "8b9186": 1, "024b16": 10, "0d9a38": 50, "d181a4": 2000, "28c97d": 1000, "80c129": 50, "be063e": 1000, "cd0660": 100, "21131b": 500, "a69776": 10, "4e32c1": 2000, "3c9598": 100, "aa9dd8": 10, "20ba4c": 5, "2a2bd7": 500, "b8302c": 10, "6380d8": 50, "eba79b": 500, "b05bce": 100, "e3dc49": 2000, "8cad02": 1, "ad8aed": 500, "72a612": 5, "13a1d7": 50, "25ec17": 1000, "0ccb12": 1000, "a659b3": 10, "456d76": 5, "d03d23": 2000, "6d44a8": 2, "2111c6": 2, "9c9d99": 5, "100616": 100, "aeda62": 100, "8776d7": 2, "650b47": 10, "c97025": 2000, "417224": 5, "83a7d6": 2000, "7732be": 50, "6e1093": 1, "509c04": 500, "523ae1": 2, "4cbd56": 2, "5385c8": 1000, "74a2be": 10, "533345": 500, "470cd8": 1, "5d2a99": 1, "a79218": 100, "e662bb": 10, "5ed25a": 5, "07da01": 1000, "88b448": 100, "202067": 5, "a3271e": 1, "506442": 1, "60e3d6": 1000, "752870": 100, "5e0594": 10, "302d88": 500, "1a28cd": 1, "06556a": 1000, "7275d1": 5, "63839d": 500, "bda319": 1, "abb3b3": 5, "09a597": 500, "ab418a": 50, "48bd42": 100, "787882": 1000, "e14805": 1, "298933": 1000, "1297d8": 2000, "7537bc": 2000, "81b83e": 10, "89bd06": 1, "ca6038": 2, "a999cb": 100, "3d3c8b": 10, "ecd5dc": 50, "b3bb0d": 50, "a825ec": 2, "0496a1": 500, "76552d": 50, "83a722": 5, "688890": 2, "4a95ca": 2000, "9d29ae": 10, "937d64": 5, "99b71b": 100, "4e1a3b": 10, "bd31c2": 1, "9563c5": 10, "c81eda": 2000, "196d26": 2, "c27ced": 500, "ba5e50": 5, "b5d3de": 500, "083373": 50, "d8b55e": 1, "0d7e8d": 50, "26d755": 5, "e0634d": 2, "a01eaa": 1, "e4cc19": 100, "512e98": 500, "bce687": 10, "407060": 100, "709777": 10, "1ea3a7": 5, "352c14": 1, "c4b3ed": 2, "e5a9b7": 5, "4e2ca4": 1000, "8e8560": 5, "d2e56e": 1, "bb0e9d": 10, "b00625": 1, "76adca": 100, "1956b6": 5, "14c533": 1, "db4402": 2000, "819be4": 2, "c518d6": 5, "004315": 1, "b0d337": 100, "67d54b": 50, "d0a1d5": 1, "82aa43": 500, "396a94": 2000, "3c4b02": 2000, "7e819b": 2, "76d879": 2000, "b52e10": 1, "b85541": 10, "2e568d": 50, "77cac4": 1, "ce25ba": 1, "e40d51": 2000, "39da97": 50, "202784": 50, "d42d4b": 5, "8b391b": 100, "6389ab": 5, "6b058e": 2, "a7486b": 10, "dd6b75": 100, "7ed1d0": 2000, "e805ea": 2, "ba7ceb": 1000, "59bb56": 10, "45c38b": 1, "52758a": 1, "204a8a": 2000, "b0011d": 50, "520249": 5, "bda0da": 2000, "2b1148": 5, "4d4ce0": 1000, "e709a8": 10, "ca92c9": 5, "3e2492": 100, "8ea35a": 50, "114597": 1, "0c00ad": 1000, "eb4b99": 2000, "548c24": 10, "100100": 5, "d2119c": 10, "86c9e7": 100, "65c70a": 5, "34002c": 50, "28cbbd": 2, "d09d87": 100, "529e1e": 1000, "9ddc53": 2000, "802b2e": 2000, "bd3d1b": 500, "0d5025": 500, "d36ad9": 2, "ad0631": 5, "2dbae2": 2000, "1a7c3d": 500, "0be871": 50, "2aa987": 50, "bab107": 1000, "2cb8b6": 1000, "01719d": 10, "539177": 2000, "c12ba9": 2000, "c854d6": 1, "4a73b5": 10, "65c28c": 2000, "986b48": 500, "69aa53": 2, "b88e40": 50, "a44e7e": 1, "d97dce": 5, "8c6c36": 2000, "9b21b7": 2, "66d994": 2000, "ebdb12": 10, "0436c0": 500, "4c68e4": 10, "3eac0b": 500, "3731c1": 50, "e9a088": 50, "2e8b41": 500, "6a0d35": 100, "063ebb": 2, "498a80": 100, "aae8ea": 5, "5a5957": 1, "421eb6": 50, "8e0916": 500, "53a470": 10, "ca4527": 1000, "0aa22d": 2000, "7b8eb4": 1, "2da257": 10, "e561be": 10, "044589": 2000, "24de02": 500, "9b6974": 1, "8a833b": 100, "3e9e8b": 500, "5d197b": 2000, "38da3c": 50, "621273": 1000, "c8d4d4": 500, "733e0a": 100, "9a47e7": 100, "bbb61e": 5, "e13362": 100, "eca881": 50, "460cb6": 10, "060b9e": 5, "abc7a0": 2, "919aca": 2, "97e4ae": 2, "3d6234": 1, "d5326c": 2000, "841b3c": 5, "b88555": 2, "08c4dc": 10, "5cc00b": 100, "9c57dd": 100, "6bb949": 1000, "e246a2": 2000, "57de93": 500, "1496b1": 1000, "ec8a54": 500, "221525": 1000, "e66078": 500, "3b9635": 10, "54454c": 1, "62580a": 1, "d6ca83": 10, "c99142": 2000, "5282cd": 2, "bd26d5": 50, "3bec9a": 10, "00776b": 2, "957654": 2000, "d3c67a": 100, "5ee6c5": 1, "41568c": 100, "7b5aa2": 100, "87656d": 1, "18e15c": 2, "149d62": 50, "d6e6cc": 10, "33b365": 1000, "bb4e32": 5, "45d545": 5, "56e515": 2, "01ed91": 2000, "39617d": 1, "455ecc": 50, "6acbea": 10, "aa95b2": 1000, "80062d": 2000, "a86b40": 10, "9564da": 100, "b16374": 10, "c7c578": 10, "944009": 5, "962224": 500, "bb7ced": 500, "94703b": 2, "d96919": 100, "e61423": 5, "c4e219": 1000, "a50bae": 1, "6ea0a4": 10, "68a929": 50, "2ac038": 2000, "7d8891": 10, "58950a": 2, "468d1b": 2000, "615700": 1, "e11c58": 500, "38cd52": 1000, "451205": 10, "da0a54": 100, "b77d52": 2000, "0bdbb9": 100, "08a55a": 1000, "63c793": 2000, "c72536": 5, "17282a": 2000, "0b2c33": 2, "d76be5": 500, "9c9e26": 1, "75ec3b": 50, "ade576": 500, "235905": 2000, "2a0edc": 5, "5d169d": 50, "34ee11": 2, "d52ca7": 500, "52e68b": 100, "13daaa": 10, "2007d1": 2, "5157a4": 5, "e66ebe": 5, "a57aa3": 500, "761c36": 10, "572719": 2, "0871d1": 10, "318c49": 1, "0eacec": 2000, "6a8761": 2, "00e362": 5, "55b255": 1, "3b6cb8": 2000, "eaa286": 1000, "57aeca": 500, "8d62b6": 1, "c04094": 2, "c34761": 2, "3daa84": 1000, "ba32d6": 1, "0757cb": 2, "edec0b": 1000, "6b5108": 1000, "23d5c1": 10, "8d9b85": 50, "0586ab": 1000, "16b8a2": 10, "c8c69b": 1, "a3c517": 1, "2db842": 1000, "c0d2c4": 5, "bb5ceb": 1000, "4363ad": 100, "04a571": 50, "371b05": 500]
            ]
    ]
    
    public class func value(token: Token, workload: Workload) -> UInt32 {
        
        var value = 0
        
        // value can be differentiated by many things, so switch on the implementation to start
        switch token.algorithm {
        case .SHA512_Append:
            // find the matricies appropriate to the ore height
            value += iterationMatch[AlgorithmType.SHA512_Append]![workload.iterations]
            value += occurrencesRewardMatrix[AlgorithmType.SHA512_Append]![workload.occurrences]
            value += pairsRewardMatrix[AlgorithmType.SHA512_Append]![workload.pairs]
        }
        
        return UInt32(value)
        
    }
    
}
