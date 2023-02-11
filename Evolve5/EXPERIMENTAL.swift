//
//  EXPERIMENTAL.swift
//  Evolve5
//
//  Created by Kenneth Stauffer on 9/29/22.
//

import Foundation

var SP1 = STRAIN_PROFILE()

func bob(_ x: Int?) {
	print("X is \(x)\n")
}

func sue(_ y: STRAIN_PROFILE?) {
	print("Sue: Y is \(y)\n")
}

func ken(_ u: UNIVERSE?) {
	if u == nil {
		print("ken: Universe is NULL\n")
	} else {
		print("ken: Universe is SET to something\n")
	}
}

func EXPERIMENTAL_MAIN() {
	var x: Int?
	
	x = 10
	bob(x)
	x = nil
	bob(x)
	
	var y: STRAIN_PROFILE?
	sue(y)
	y = SP1
	sue(y)
	
	var u: UNIVERSE?
	ken(u)
}
