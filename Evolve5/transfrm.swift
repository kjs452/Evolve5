/*
 * Copyright (c) 1991 Ken Stauffer, All Rights Reserved
 */

/***********************************************************************
 *
 * This file contains functions for doing transforms between a
 * "window" coordinate system and a "world" coordinate system
 *
 *           top
 *      +---------------+
 *      |               |
 * left |               | right
 *      |               |
 *      |               |
 *      +---------------+
 *           bottom
 *
 *      The following must be true for all WINDOW transform rects:
 *              left < right && top < bottom
 *
 *      The axis of WORLD transforms may be reversed.
 *
 *      Each viewport can allocate one transform for the duration of the
 *      program and use TF_Set() to change the transform as the user
 *      zooms/resized the window.
 *
 *                      Module Description
 *
 * A TF_TRANSFORM object contains the information about the world and window
 * coordinates. TF_Use() is used to make that transform "active"
 * When done using a TF_TRANSFORM, call TF_Done(). The transform which
 * was active prior to a TF_Use() is restored after a call to  TF_Done().
 *
 * TF_Make() and TF_Delete() simply do the malloc() / free() of the TF_TRANSFORM
 * object.
 *
 * handle = TF_Make();
 *      Allocate a transform handle. (not nessesary).
 *
 * TF_Delete(handle);
 *      Free a handle object. (not nessesary).
 *
 * TF_Set(handle, &win_rect, &world_rect );
 *      Set the window and world rect for 'handle'.
 *      If win_rect is NULL or world_rect
 *      is NULL, it is not changed.
 *
 * TF_WinToWorld(handle, x, y, px, py);
 *  * TF_WorldToWin(handle, x, y, px, py);
 * TF_WinDist(handle, w, h, pw, ph);
 * TF_WorldDist(handle, w, h, pw, ph);
 *      These functions all use the 'current' transform.
 */
//
//  transfrm.swift
//  Evolve5
//
//  Created by Kenneth Stauffer on 9/4/22.
//

import Foundation

struct TF_RECT {
    var left: Double
    var right: Double
    var top: Double
    var bottom: Double
    
    init() {
        self.init(0,0,0,0)
    }
    
    init(_ l: Double, _ r: Double, _ t: Double, _ b: Double) {
        left = l
        right = r
        top = t
        bottom = b
    }
}

struct TF_TRANSFORM {
    var win: TF_RECT
    var world: TF_RECT
    var hratio_world: Double
    var wratio_world: Double
    var hratio_win: Double
    var wratio_win: Double
    
    init() {
		var winx: TF_RECT
		var worldx: TF_RECT

        winx = TF_RECT(0, 1, 0, 1)
        worldx = TF_RECT(0, 1, 0, 1)
        self.init(winx, worldx)
    }
    
    init(_ winx: TF_RECT, _ worldx: TF_RECT) {
        win = winx
        world = worldx

        wratio_world = (win.right - win.left) /
                                        (world.right - world.left)
        wratio_win = (world.right - world.left) /
                                        (win.right - win.left)

        hratio_world = (win.bottom - win.top) /
                                        (world.bottom - world.top)

        hratio_win = (world.bottom - world.top) /
                                        (win.bottom - win.top)
    }
    
    func WorldToWin(_ X: Double, _ Y: Double) -> (Double, Double) {
        let x = win.left + (X - world.left) * wratio_world
		let y = win.top + (Y - world.top) * hratio_world
        return (x, y)
    }
    
    func WinToWorld(_ X: Double, _ Y: Double) -> (Double, Double) {
        let x = world.left + (X - win.left) * wratio_win
		let y = world.top + (Y - win.top) * hratio_win
        return (x, y)
    }
	
	 /***********************************************************************
	  *      x and y comprise two components of a vector in
	  *      world (window) units. This function returns the length
	  *      of the vector in window (world) units.
	  */
	func WorldDistance(_ x: Double, _ y: Double) -> Double {
		var X, Y: Double
		X = 0.0 + (x - 0.0) * wratio_world
		Y = 0.0 + (y - 0.0) * hratio_world

		return( sqrt(X*X + Y*Y) );
	}
	
	func WinDistance(_ x: Double, _ y: Double) -> Double {
		var X, Y: Double
		X = 0.0 + (x - 0.0) * wratio_win
		Y = 0.0 + (y - 0.0) * hratio_win

		return( sqrt(X*X + Y*Y) );
	}

	//
	// update the window transform 'win' so that it has the same
	// aspect ratio of the world transform.
	//
    func preserve_aspect_ratio(_ win: inout TF_RECT, _ world: TF_RECT) -> Void {
		var window_ratio: Double;
		var world_ratio: Double;

		window_ratio = (win.bottom - win.top) / (win.right - win.left);
		world_ratio = (world.bottom - world.top) / (world.right - world.left);

		if world_ratio > window_ratio {
				win.right = win.left +
								(win.bottom - win.top) / world_ratio;
		} else {
				win.bottom = win.top +
								(win.right - win.left) * world_ratio;
		}
	}

};

