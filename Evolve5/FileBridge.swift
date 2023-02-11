//
//  FileBridge.swift
//  Evolve5
//
//  Created by Kenneth Stauffer on 9/7/22.
//

import Foundation

fileprivate var g_data = Data()
fileprivate var g_pos: Int = 0

//
// This is called from swift. it sets a global variable to hold 'd'
//
public func SetEvolveFileBridgeObject(_ d: Data)
{
	g_data = d
	g_pos = 0
}

public func GetEvolveFileBridgeObject() -> Data
{
	return g_data;
}

@_cdecl("EvolveFileBridge_rewind")
public func EvolveFileBridge_rewind() {
	g_pos = 0
}

//
// The C/C++ code calls this when it wants to read the next 'reqlen' bytes
// from the FileBridgeObject
//
@_cdecl("EvolveFileBridge_read")
public func EvolveFileBridge_read(buf: UnsafeMutablePointer<UInt8>, reqlen: Int) -> Int {
	// read the next 'len' bytes from 'g_data' and return numbers of  bytes read
	var len: Int
	
	if g_pos >= g_data.count {
		return 0
	}
	
	if g_pos + reqlen <= g_data.count {
		len = reqlen
	} else {
		len = g_data.count - g_pos
	}
	
	let r = Range<Data.Index>(NSRange(location: g_pos, length: len))!

	g_data.copyBytes(to: buf, from: r)
	
	g_pos += len

	return len
}

//
// The C/C++ code calls this to write len bytes to the FileBridgeObject
//
@_cdecl("EvolveFileBridge_write")
public func EvolveFileBridge_write(buf: UnsafePointer<UInt8>, len: Int) -> Int {
	
	//let s = String(cString: buf)
	//print("it wants to write len \(len) bytes, they are: \"\(s)\"")
	
	g_data.append(buf, count: len)
	
	return len
}


