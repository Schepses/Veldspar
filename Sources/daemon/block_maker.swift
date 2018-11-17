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
import VeldsparCore

// this class is a background thread which constantly monitors the time, and creates new blocks when required, checks quorum, and queries other nodes to make sure we posess all of the transactions and none are missed.

class BlockMaker {
    
    class func Loop() {
        
        while true {
            
            let currentTime = consensusTime()
            if UInt64(currentTime) > UInt64(Config.BlockchainStartDate) {
                
                // get the current height, and work out which block should be created and when
                let blockHeightForTime = ((currentTime - UInt64(Config.BlockchainStartDate)) / UInt64(Config.BlockTime * 1000))
                
                if blockchain.height() < blockHeightForTime {
                    
                    for index in Int(blockchain.height()+1)...Int(blockHeightForTime) {
                        
                        // produce the block, hash it, seek quorum, then write it
                        let previousBlock = blockchain.blockAtHeight(index-1, includeTransactions: false)
                        
                        var newBlock = Block()
                        newBlock.height = index
                        
                        // query the table for this target block height
                        let ledgers = blockchain.LedgersForBlock(index)
                        
                        if newBlock.transactions == nil {
                            newBlock.transactions = []
                        }
                        
                        for l in ledgers {
                            newBlock.transactions!.append(l)
                        }
                        
                        newBlock.hash = newBlock.GenerateHashForBlock(previousHash: previousBlock?.hash ?? Data())
                        newBlock.transactions = []
                        
                        logger.log(level: .Info, log: "Generated block @ height \(index) with hash \(newBlock.hash!.toHexString().lowercased())")
        
                        if !settings.isSeedNode {
                            
                            var agreement: Float = 0.0
                            var responses: Float = 0.0
                            var attempts = 0
                            
                            // now contact the seed node(s) to get their hashes
                            var nodes = Config.SeedNodes
                            if isTestNet {
                                nodes = Config.TestNetNodes
                            }
                            
                            while true {
                                for n in nodes {
                                    let blockHash = comms.hashForBlock(address: n, height: index)
                                    if blockHash != nil {
                                        if blockHash!.ready! {
                                            responses += 1.0
                                            if blockHash?.hash == newBlock.hash {
                                                agreement += 1.0
                                            } else {
                                                
                                            }
                                        } else {
                                            // do nothing
                                        }
                                    } else {
                                        // timeout, or error.  Do nothing, because it will be covered in a retry
                                    }
                                }
                                if responses == 1.0 {
                                    break
                                }
                                if attempts == 30 {
                                    logger.log(level: .Error, log: "Unable to communicate with network for 15 mins, exiting as impossible to verify block image.")
                                    exit(1)
                                }
                                attempts += 1
                                logger.log(level: .Info, log: "Failed to seek agreement for block hash with the network, will retry in 30 seconds.")
                                Thread.sleep(forTimeInterval: 30)
                            }
                            
                            // check the level of quorum
                            let quorum = agreement / responses
                            if quorum < 1.0 {
                                
                                logger.log(level: .Info, log: "Block signature verification failed, attempting to re-sync block data with network")
                                
                                // something we have is either missing or extra :(.  Ask the authoritive node for all of the transactions for a certain height
                                var authoritiveBlock = comms.blockAtHeight(height: index)
                                if authoritiveBlock == nil {
                                    // unable to get the block data from the seed node, wait and try again
                                    logger.log(level: .Info, log: "Network failed to return block data, waiting 30 seconds and trying again.")
                                    Thread.sleep(forTimeInterval: 30.0)
                                    authoritiveBlock = comms.blockAtHeight(height: index)
                                }
                                
                                if authoritiveBlock == nil {
                                    logger.log(level: .Info, log: "Network failed to return block data for verification.  Aborting production of this block.")
                                    break
                                }
                                
                                // we have the authoritive block data, so poop-can the current block data and re-write it with the new.
                                
                                logger.log(level: .Info, log: "Block signature verification passed, committing block \(index) into blockchain with signature \(newBlock.hash!.toHexString().lowercased())")
                                
                                if blockchain.addBlock(newBlock) {
                                    blockchain.setTransactionStateForHeight(height: index, state: .Verified)
                                } else {
                                    break
                                }
                                
                            } else {
                                
                                logger.log(level: .Info, log: "Block signature verification passed, committing block \(index) into blockchain with signature \(newBlock.hash!.toHexString().lowercased())")
                                if blockchain.addBlock(newBlock) {
                                    blockchain.setTransactionStateForHeight(height: index, state: .Verified)
                                } else {
                                    break
                                }
                                
                            }
                            
                        } else {
                            
                            // this is a/the seed node, so just write this (until we go for quorum model in v0.2.0)
                            logger.log(level: .Info, log: "Block signature verification passed, committing block \(index) into blockchain with signature \(newBlock.hash!.toHexString().lowercased())")
                            
                            if blockchain.addBlock(newBlock) {
                                blockchain.setTransactionStateForHeight(height: index, state: .Verified)
                            } else {
                                break
                            }
                            
                        }
                        
                        logger.log(level: .Info, log: "Blockchain produced block '\(index)'")
                        if settings.blockchain_export_data {
                            BlockMaker.export_block(index)
                        }

                    }
                    
                }
                
            }
            
            Thread.sleep(forTimeInterval: 5)

            
        }
        
    }
    
    class func export_block(_ height: Int) {
        
        do {
            
            try? FileManager.default.createDirectory(atPath: "./cache/blocks", withIntermediateDirectories: true, attributes: [:])
            let filePath = "./cache/blocks/\(height).block"
            
            let block = blockchain.blockAtHeight(height, includeTransactions: true)
            let e = JSONEncoder()
            let d = try? e.encode(block)
            
            if d != nil {
                try d!.write(to: URL(fileURLWithPath: filePath))
            }
            
        } catch {
            
            print(error)
            
        }
        
        // export the block height object
        let filePath = "./cache/blocks/current.height"
        var newHeightObject = CurrentHeightObject()
        newHeightObject.height = blockchain.height()
        let d = try? JSONEncoder().encode(newHeightObject)
        if d != nil {
            try? d!.write(to: URL(fileURLWithPath: filePath))
        }
        
        
    }
    
}
