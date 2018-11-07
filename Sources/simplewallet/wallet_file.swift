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
import SWSQLite
import VeldsparCore
import Ed25519
import CryptoSwift

enum WalletErrors : Error {
    case UnableToEncrypt
    case InvalidPassword
    case InvalidSeed
}

struct Address : Codable {
    
    var addressId: String?
    var seed: String?
    var height: Int?
    var name: String?
    
    init() {
    }
    
}

struct Transfer : Codable {
    
    var id: Int?
    var timestamp: Int?
    var transferGroup: String?
    var tokenValue: Int?
    
    init() {}
    
}

class WalletFile {
    
    private var db: SWSQLite
    private var pw: String
    private var addressCache: [String]?
    
    init(_ walletFilePath: String, password: String) {
        
        db = SWSQLite(path: "./", filename: walletFilePath)
        
        db.create(Address(), pk: "addressId", auto: false, indexes:[])
        db.create(Transfer(), pk: "id", auto: true, indexes:[])
        db.create(Ledger(), pk: "id", auto: true, indexes:["address"])
        
        pw = password
        
    }
    
    func addExistingAddress(_ uuid: String) throws -> String {
        
        var encSeed: String?
        
        do {
            let aes = try AES(key: Data(bytes: pw.bytes.sha512()).prefix(32).bytes, blockMode: CBC(iv: Data(bytes:pw.bytes.sha512().sha512()).prefix(16).bytes), padding: Padding.pkcs7)
            
            encSeed = try aes.encrypt(uuid.bytes).base58EncodedString
            
        } catch {
            
            throw WalletErrors.UnableToEncrypt
            
        }
        
        var oldMethod = false;
        if uuid.count < 36 {
            throw WalletErrors.InvalidSeed
        }
        
        if uuid.count == 36 {
            oldMethod = true
        }
        
        var seed: [UInt8] = []
        if oldMethod {
            seed = uuid.sha224().data(using: String.Encoding.ascii)!.prefix(upTo: 32).bytes
        } else {
            seed = Data(bytes:uuid.bytes.sha512()).prefix(32).bytes
        }
        let k = Keys(seed)
        _ = db.execute(sql: "INSERT OR REPLACE INTO address (addressId,seed,height,name) VALUES (?,?,?,?);", params:[k.address(), encSeed!, 0, k.address()])
        
        addressCache = nil
        
        return k.address()
        
    }
    
    func setHeight(_ height: Int) {
        _ = db.execute(sql: "UPDATE address SET height = ?", params: [height])
        if height == 0 {
            // this is a reset, so we need to scrub the database
            _ = db.execute(sql: "DELETE FROM address", params: [])
            _ = db.execute(sql: "DELETE FROM token", params: [])
            _ = db.execute(sql: "DELETE FROM transfer", params: [])
        }
    }
    
    func height() -> Int {
        
        let results = db.query(sql: "SELECT MIN(height) as lowest FROM address", params: [])
        if results.error == nil && results.results.count > 0 {
            
            for r in results.results {
                return r["lowest"]!.asInt() ?? 0
            }
            
        }
        
        return 0
    }
    
    func isDecodable() -> Bool {
        for a in self.addresses() {
            if seedForAddress(a) == nil {
                return false
            }
        }
        return true
    }
    
    func createNewAddress() throws -> String {
        
        let uuid = UUID().uuidString.lowercased() + "-" + UUID().uuidString.lowercased()
        
        var encSeed: String?
        
        do {
            let aes = try AES(key: Data(bytes: pw.bytes.sha512()).prefix(32).bytes, blockMode: CBC(iv: Data(bytes:pw.bytes.sha512().sha512()).prefix(16).bytes), padding: Padding.pkcs7)
            
            encSeed = try aes.encrypt(uuid.bytes).base58EncodedString
            
        } catch {
            
            throw  WalletErrors.UnableToEncrypt
            
        }
        
        let seed = Data(bytes:uuid.bytes.sha512()).prefix(32).bytes
        let k = Keys(seed)
        _ = db.execute(sql: "INSERT OR REPLACE INTO address (addressId,seed,height,name) VALUES (?,?,?,?);", params:[k.address(), encSeed!, 0,k.address()])
        
        addressCache = nil
        
        return k.address()
        
    }
    
    func deleteAddress(_ address: String) {
        
        _ = db.execute(sql: "DELETE FROM address WHERE addressId = ?;", params: [address])
        _ = db.execute(sql: "DELETE FROM token WHERE address = ?;", params: [address])
        
    }
    
    func nameAddress(_ address: String, name: String) {
        
        _ = db.execute(sql: "UPDATE address SET name = ? WHERE addressId = ?;", params: [name, address])
        
    }
    
    func addresses() -> [String] {
        
        if addressCache != nil {
            return addressCache!
        }
        
        var retValue: [String] = []
        let results = db.query(sql: "SELECT addressId FROM address", params: [])
        if results.error == nil && results.results.count > 0 {
            
            for r in results.results {
                retValue.append(r["addressId"]!.asString()!)
            }
            
        }
        
        addressCache = retValue
        
        return retValue
        
    }
    
    func addressesBytes() -> [Data] {
        
        var retValue: [Data] = []
        let results = db.query(sql: "SELECT addressId FROM address", params: [])
        if results.error == nil && results.results.count > 0 {
            
            for r in results.results {
                retValue.append(Crypto.strAddressToData(address: r["addressId"]!.asString()!))
            }
            
        }
        
        return retValue
        
    }
    
    func seedForAddress(_ address: String) -> String? {
        
        let results = db.query(sql: "SELECT seed FROM address WHERE addressId = ?", params: [address])
        if results.error == nil && results.results.count > 0 {
            
            for r in results.results {
                
                let seed = r["seed"]!.asString()!
                do {
                    
                    // this is where we check for the old format file & old AES implementation.  It's upgraded on write out.
                    let encryptedData = seed.base58DecodedData
                    let aes = try AES(key: Data(bytes: pw.bytes.sha512()).prefix(32).bytes, blockMode: CBC(iv: Data(bytes:pw.bytes.sha512().sha512()).prefix(16).bytes), padding: Padding.pkcs7)
                    let decryptedSeed = String(bytes: try aes.decrypt(Array(encryptedData!)), encoding: .ascii)
                    if !decryptedSeed!.contains("-") {
                        return nil
                    }
                    return decryptedSeed!
                    
                } catch  {
                    
                }
                
            }
            
        }
        
        return nil
        
    }
    
    func setNameForAddress(_ address: String, name: String) {
        _ = db.execute(sql: "UPDATE address SET name = ? WHERE addressId = ?", params: [name, address])
    }
    
    func nameForAddress(_ address: String) -> String? {

        let results = db.query(sql: "SELECT name FROM address WHERE addressId = ?", params: [address])
        if results.error == nil && results.results.count > 0 {
            
            for r in results.results {
                return r["name"]!.asString()!
            }
            
        }
        
        return nil
        
    }
    
    func addTokenIfOwned(_ token: Ledger) -> Int {
        
        if addressesBytes().contains(token.destination!) {
            
            _ = db.put(token)
            return token.value!
            
        }
        
        return 0
        
    }
    
    func removeTokenIfOwned(_ token: Ledger) -> Int {
        
        if !addressesBytes().contains(token.destination!) {
            
            if db.query(sql: "SELECT address FROM Ledger WHERE address = ? AND ore = ?", params: [token.address!, token.ore!]).results.count > 0 {
                _ = db.execute(sql: "DELETE FROM Ledger WHERE address = ? AND ore = ?", params: [token.address!, token.ore!])
                return token.value!
            }
            
        }

        return 0
        
    }
    
    func balance() -> Int {
        
        let results = db.query(sql: "SELECT SUM(value) as totalValue FROM Ledger;", params: [])
        if results.error == nil && results.results.count > 0 {
            for r in results.results {
                return r["totalValue"]!.asInt() ?? 0
            }
        }
        return 0
        
    }
    
    func balance(address: String) -> Int {
        
        let results = db.query(sql: "SELECT SUM(value) as totalValue FROM Ledger WHERE destination = ?", params: [Crypto.strAddressToData(address: address)])
        if results.error == nil && results.results.count > 0 {
            for r in results.results {
                return r["totalValue"]!.asInt()!
            }
        }
        return 0
        
    }
    
    
}
