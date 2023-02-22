//
//  EvolveCanvas.swift
//  Evolve5
//
//  Created by Kenneth Stauffer on 9/3/22.
//

import Cocoa
import CoreGraphics

class EvolveCanvas: NSView {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
		rebuild_tracking_area()
        
		zh.set_world(0, 0, 500, 500)
        zh.set_window(0, 0, frame.width, frame.height)
        zh.resize()
    }

	func rebuild_tracking_area()
	{
        let bounds = NSRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        
        let ta: NSTrackingArea = NSTrackingArea(rect: bounds,
				options: [NSTrackingArea.Options.activeAlways,
				NSTrackingArea.Options.mouseMoved,
				NSTrackingArea.Options.mouseEnteredAndExited],
				owner: self, userInfo: nil)
        
		addTrackingArea(ta)
	}

	//
	// Use this to configure this view for use as main simulation windows
	// 'cb' is a function to be called when the Cusor Changes via mouse moves
	//	
	func doit_universe(
					_ u: UnsafeMutablePointer<UNIVERSE>,
					_ cb: @escaping (_ x: Int, _ y: Int) -> Void) {

		mode = MODE.MAIN
		change_cursor_cb = cb
		self.u = u
		zh.set_world(0, 0, Double(u.pointee.width), Double(u.pointee.height))
		zh.set_window(0, 0, frame.width, frame.height)
		zh.resize()
		setNeedsDisplay(frame)
		barriersNeedRebuilt = true
		rebuild_tracking_area()
	}

	//
	// Use this to configure this view for use in ViewOrganism dialog
	// 'c' is the cell being shown
	//	
	func doit_cell(_ u: UnsafeMutablePointer<UNIVERSE>, _ c: UnsafeMutablePointer<CELL>, _ cb: @escaping (_ x: Int, _ y: Int) -> Void) {
		var o: UnsafeMutablePointer<ORGANISM>

		mode = MODE.VIEW

		cell = c
		o = c.pointee.organism
		self.u = u

		change_cell_cb = cb

		let r = organism_bounding_box(o)

		zh.set_world(r.minX, r.minY, r.maxX, r.maxY)
		zh.set_window(0, 0, frame.width, frame.height)
		zh.resize()
		setNeedsDisplay(frame)
		barriersNeedRebuilt = true
		rebuild_tracking_area()
	}

	func organism_bounding_box(_ o: UnsafeMutablePointer<ORGANISM>) -> NSRect {
		var curr: UnsafeMutablePointer<CELL>?
		var x, y: Int
		var minx, miny: Int
		var maxx, maxy: Int

		minx = Int.max
		miny = Int.max
		maxx = -1
		maxy = -1
		curr = o.pointee.cells
		while curr != nil {
			x = Int( curr!.pointee.x )
			y = Int( curr!.pointee.y )

			if x < minx { minx = x }
			if x > maxx { maxx = x }
			if y < miny { miny = y }
			if y > maxy { maxy = y }

			curr = curr!.pointee.next
		}

		minx -= 2
		miny -= 2
		maxx += 2
		maxy += 2

		return NSRect(x: minx, y: miny, width: (maxx-minx), height: (maxy-miny))
	}

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
		
        clear_screen()
		redraw_universe()
	}

    override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)
        print("resize! \(frame)")

		//
		// remove the old tracking area
		//
        let oldBounds = NSRect(x: 0, y: 0, width: oldSize.width, height: oldSize.height)
        
        let ota: NSTrackingArea = NSTrackingArea(rect: oldBounds,
				options: [NSTrackingArea.Options.activeAlways,
				NSTrackingArea.Options.mouseMoved,
				NSTrackingArea.Options.mouseEnteredAndExited],
				owner: self, userInfo: nil)

		removeTrackingArea(ota)
        
		zh.set_window(0, 0, frame.width, frame.height)
        zh.resize()
		rebuild_tracking_area()
		barriersNeedRebuilt = true
		cancelTweakEnergy()
    }
    
    func clear_screen() {
        NSGraphicsContext.current!.saveGraphicsState()
        NSColor.white.setFill()
		let r = NSRect(x: 0, y: 0, width: frame.width, height: frame.height)
        r.fill()
        NSGraphicsContext.current!.restoreGraphicsState()
    }

	func rebuild_barrier(_ cg: CGContext, _ x: Int32, _ y: Int32) {
		var n, m, j, k: Double
		let px = Double(x)
		let py = Double(y)

		(n, m) = zh.tf.WorldToWin(px - 0.5, py - 0.5)
		(j, k) = zh.tf.WorldToWin(px + 0.5, py + 0.5)
		_ = NSRect(x: n, y: m, width: j-n, height: k-m)
		let c = CGRect(x: n, y: m, width: j-n, height: k-m)

		cg.setFillColor(CGColor.black)
		cg.fill(c)
	}

	func clip_bounds(_ xstart: inout Int32, _ xend: inout Int32, _ ystart: inout Int32, _ yend: inout Int32) {
		if xstart < 0 {
			xstart = 0
		}

		if xstart >= u!.pointee.width {
			xstart = u!.pointee.width-1
		}

		if xend < 0 {
			xend = 0
		}
		
		if xend >= u!.pointee.width {
			xend = u!.pointee.width-1
		}

		if ystart < 0 {
			ystart = 0
		}

		if ystart >= u!.pointee.height {
			ystart = u!.pointee.height-1
		}

		if yend < 0 {
			yend = 0
		}
		
		if yend >= u!.pointee.height {
			yend = u!.pointee.height-1
		}
	}
	
	func rebuild_barrier_layer() {
		var ugrid = UNIVERSE_GRID()
		var t: GRID_TYPE = GT_BLANK
		var fx, fy: Double
		var xstart, ystart, xend, yend: Int32
		var cg: CGContext
		
		cg = NSGraphicsContext.current!.cgContext
		
		barrierLayer = CGLayer(cg,
							   size: CGSize(width: frame.width, height: frame.height), auxiliaryInfo: nil)!

		(fx, fy) = zh.tf.WinToWorld(0, 0)
		xstart = Int32(floor(fx))
		ystart = Int32(floor(fy))

		(fx, fy) = zh.tf.WinToWorld(frame.width, frame.height)
		xend = Int32(floor(fx))
		yend = Int32(floor(fy))

		clip_bounds(&xstart, &xend, &ystart, &yend)

		let cg2 = barrierLayer!.context
		
		for x in xstart ... xend {
			for y in ystart ... yend {
				t = Grid_Get(u, x, y, &ugrid)
				if t == GT_BARRIER {
					rebuild_barrier(cg2!, x, y)
				}
			}
		}

		barriersNeedRebuilt = false
	}
	
	func redraw_barriers() {
		var cg: CGContext

		if barriersNeedRebuilt {
			rebuild_barrier_layer()
		}
		
		cg = NSGraphicsContext.current!.cgContext

		let rect = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
		
		cg.draw(barrierLayer!, in: rect)
	}

	func redraw_universe() {
		var ugrid = UNIVERSE_GRID()
		var t: GRID_TYPE = GT_BLANK
		var fx, fy: Double
		var xstart, ystart, xend, yend: Int32

		(fx, fy) = zh.tf.WinToWorld(0, 0)
		xstart = Int32(floor(fx))
		ystart = Int32(floor(fy))

		(fx, fy) = zh.tf.WinToWorld(frame.width, frame.height)
		xend = Int32(floor(fx))
		yend = Int32(floor(fy))

		clip_bounds(&xstart, &xend, &ystart, &yend)
		
		redraw_border()
		redraw_barriers()
		
		for x in xstart ... xend {
			for y in ystart ... yend {
				t = Grid_Get(u, x, y, &ugrid)
				redraw_element(x, y, t, &ugrid)
			}
		}
		
		var o = UnsafeMutablePointer<ORGANISM>?(nil)
		o = Universe_GetSelection(u!)
		if o != nil {
			if mode == MODE.MAIN {
				draw_selection(o!)
			} else {
				draw_selected_cell(cell!)
			}
		}
		
		draw_mouse_pos()
	}
	
	func draw_mouse_pos() {
		var n, m, j, k: Double
		var fx, fy: Double

		var x: Int32 = u!.pointee.mouse_x
		var y: Int32 = u!.pointee.mouse_y

		fx = Double(x)
		fy = Double(y)
		
		if x == -1 || y == -1 {
			return
		}
		(n, m) = zh.tf.WorldToWin(fx - 0.5, fy - 0.5)
		(j, k) = zh.tf.WorldToWin(fx + 0.5, fy + 0.5)
		let r = NSRect(x: n, y: m, width: j-n, height: k-m)
		
		let p = NSBezierPath()
		p.move(to: NSPoint(x: r.minX, y: r.minY))
		p.line(to: NSPoint(x: r.maxX, y: r.maxY))
		p.move(to: NSPoint(x: r.minX, y: r.maxY))
		p.line(to: NSPoint(x: r.maxX, y: r.minY))
		NSColor.red.setStroke()
		p.lineWidth = 2
		p.stroke()
	}
	
	func draw_select_box(_ x: Double, _ y: Double, _ dist: Double) {
		var d: Double
		
		if dist < 4 { d = 4 } else { d = dist }
	
		let rect = NSRect(x: x, y: y, width: d, height: d)
		NSColor.black.setFill()
		rect.fill()
	}
	
	func draw_selection(_ o: UnsafeMutablePointer<ORGANISM>) {
		var first: Bool = true
		var curr: UnsafeMutablePointer<CELL>?
		var dist: Double
		var fx, fy: Double
		var ob = TF_RECT()
		
		curr = o.pointee.cells
		while curr != nil {
			if first {
				first = false
				ob.left = Double(curr!.pointee.x)
				ob.top = Double(curr!.pointee.y)
				ob.right = Double(curr!.pointee.x)
				ob.bottom = Double(curr!.pointee.y)
			} else {
				if Double(curr!.pointee.x) > ob.right {
					ob.right = Double(curr!.pointee.x)
				}

				if Double(curr!.pointee.x) < ob.left {
					ob.left = Double(curr!.pointee.x)
				}

				if Double(curr!.pointee.y) > ob.bottom {
					ob.bottom = Double(curr!.pointee.y)
				}

				if Double(curr!.pointee.y) < ob.top {
					ob.top = Double(curr!.pointee.y)
				}
			}

			curr = curr!.pointee.next
		}

		dist = zh.tf.WorldDistance(1.0, 0.0) * 0.5

		(fx, fy) = zh.tf.WorldToWin(ob.left - 0.75, ob.top - 0.75)
		draw_select_box(fx, fy, dist)

		(fx, fy) = zh.tf.WorldToWin(ob.left - 0.75, ob.bottom + 0.25)
		draw_select_box(fx, fy, dist)

		(fx, fy) = zh.tf.WorldToWin(ob.right + 0.25, ob.top - 0.75)
		draw_select_box(fx, fy, dist)

		(fx, fy) = zh.tf.WorldToWin(ob.right + 0.25, ob.bottom + 0.25)
		draw_select_box(fx, fy, dist)
	}

	func draw_selected_cell(_ c: UnsafeMutablePointer<CELL>) {
		var w, h: Double
		var j, k: Double

		let x = Double( c.pointee.x )
		let y = Double( c.pointee.y )

		(w, h) = zh.tf.WorldToWin(x - 0.5, y - 0.5)
		(j, k) = zh.tf.WorldToWin(x + 0.5, y + 0.5)
		let r = NSRect(x: w, y: h, width: j-w, height: k-h)
		let p = NSBezierPath(rect: r)
		NSColor.blue.setStroke()
		p.lineWidth = 2
		p.stroke()
	}
	
	func redraw_border() {
		var w, h: Double
		var j, k: Double

		(w, h) = zh.tf.WorldToWin(0.0 - 0.5, 0.0 - 0.5)
		(j, k) = zh.tf.WorldToWin(Double(u!.pointee.width) + 0.5, Double(u!.pointee.height) + 0.5)
		let r = NSRect(x: w, y: h, width: j-w, height: k-h)
		let p = NSBezierPath(rect: r)
		NSColor.blue.setStroke()
		p.lineWidth = 2
		p.stroke()
	}
	
	func redraw_element(_ x: Int32, _ y: Int32, _ t: GRID_TYPE, _ ugrid: UnsafeMutablePointer<UNIVERSE_GRID>) {
		var n, m, j, k: Double
		var radioactive: Bool = false
		let px = Double(x)
		let py = Double(y)
		var c: UnsafeMutablePointer<CELL>

		if t == GT_BLANK || t == GT_BARRIER {
			return
		}
		
		(n, m) = zh.tf.WorldToWin(px - 0.5, py - 0.5)
		(j, k) = zh.tf.WorldToWin(px + 0.5, py + 0.5)
		let r = NSRect(x: n, y: m, width: j-n, height: k-m)
		
		if t == GT_BARRIER {
			NSColor.black.setFill()
		} else if t == GT_SPORE {
			let f: Int32 = ugrid.pointee.u.spore.pointee.sflags
			if (f & 1) != 0 {
				radioactive = true
			}

			sporeColor.setFill()
			//NSColor.blue.setFill()
		} else if t == GT_CELL {
			let f: Int32 = ugrid.pointee.u.cell.pointee.organism.pointee.oflags
			if (f & 1) != 0 {
				radioactive = true
			}
			var term: Int32
			var kfm = ugrid.pointee.u.cell.pointee.kfm
			term = kforth_machine_terminated(&kfm)
			if term != 0 {
				NSColor.red.setFill()
			} else {
				var strain: Int32
				c = ugrid.pointee.u.cell
				strain = c.pointee.organism.pointee.strain
				if mode == MODE.VIEW {
					if cell!.pointee.organism != c.pointee.organism {
						strainColor2[Int(strain)].setFill()
					} else {
						strainColor[Int(strain)].setFill()
					}
				} else {
					strainColor[Int(strain)].setFill()
				}
			}
		} else if t == GT_ORGANIC {
			NSColor.white.setFill()
		}

		r.fill()
		if radioactive {
			radioActive.setFill()
		} else {
			NSColor.black.setFill()
		}
		r.frame()
	}

	func create_barrier_grid(_ x: Int, _ y: Int) {
		var gt: GRID_TYPE
		var ugrid = UNIVERSE_GRID()
		var cg: CGContext

		if x < 0 || x >= u!.pointee.width {
			return
		}

		if y < 0 || y >= u!.pointee.height {
			return
		}

		gt = Universe_Query(u, Int32(x), Int32(y), &ugrid)
		if gt != GT_BLANK && gt != GT_BARRIER {
			return
		}

		if gt == GT_BLANK && barrierDrawState {
			Universe_SetBarrier(u, Int32(x), Int32(y))

		} else if gt == GT_BARRIER && !barrierDrawState {
			Universe_ClearBarrier(u, Int32(x), Int32(y))
		}

		cg = barrierLayer!.context!
		rebuild_barrier(cg, Int32(x), Int32(y))
	}

	func create_barrier_grids(_ x: Int, _ y: Int) {
		create_barrier_grid(x, y)
		if rtcMode == RTC.THICK_BARRIER {
			create_barrier_grid(x, y-1)
			create_barrier_grid(x, y+1)
			create_barrier_grid(x-1, y)
			create_barrier_grid(x+1, y)
		}
	}

	func create_barrier(_ p1: NSPoint, _ p2: NSPoint, _ thick: Bool) {
		var fx, fy: Double
		var x0, y0: Int
		var x1, y1: Int
		var dx, dy: Int
		var stepx, stepy: Int
		var fraction: Int

		(fx, fy) = zh.tf.WinToWorld(p1.x, p1.y)
		x0 = Int(floor(fx))
		y0 = Int(floor(fy))

		(fx, fy) = zh.tf.WinToWorld(p2.x, p2.y)
		x1 = Int(floor(fx))
		y1 = Int(floor(fy))

		//
		// Traverse a line from (x0, y0) to (x1, y1)
		//
		dy = y1 - y0
		dx = x1 - x0

		if( dy < 0 ) {
				dy = -dy
				stepy = -1
		} else {
				stepy = 1
		}

		if( dx < 0 ) {
				dx = -dx
				stepx = -1
		} else {
				stepx = 1
		}

		dy <<= 1				// dy is now 2*dy
		dx <<= 1				// dx is now 2*dx

		create_barrier_grids(x0, y0)

		if (dx > dy) {
				fraction = dy - (dx >> 1)				// same as 2*dy - dx
				while( x0 != x1 ) {
						if( fraction >= 0 ) {
								y0 += stepy
								fraction -= dx			// same as fraction -= 2*dx
						}
						x0 += stepx
						fraction += dy					// same as fraction -= 2*dy

						create_barrier_grids(x0, y0)
				}
		} else {
				fraction = dx - (dy >> 1)
				while( y0 != y1 ) {
						if( fraction >= 0 ) {
								x0 += stepx
								fraction -= dy
						}
						y0 += stepy
						fraction += dx

						create_barrier_grids(x0, y0)
				}
		}
	}

    override func rightMouseDragged(with event: NSEvent) {
        print("Right Dragged")

		p2.x = event.locationInWindow.x - frame.minX
		p2.y = event.locationInWindow.y - frame.minY

		switch(rtcMode) {
		case RTC.MOVE_ORGANISM:
			needsDisplay = true
			do_omove(p1, p2)
			break

		case RTC.THICK_BARRIER:
			needsDisplay = true
			barriersNeedRebuilt = true
			create_barrier(p1, p2, true)
			break

		case RTC.THIN_BARRIER:
			needsDisplay = true
			barriersNeedRebuilt = true
			create_barrier(p1, p2, false)
			break

		default:
			break
		}

		p1 = p2
	}
    
    override func mouseDragged(with event: NSEvent) {
        print("Mouse Dragged")
		var xdiff: Double
		var ydiff: Double

		p2.x = event.locationInWindow.x - frame.minX
		p2.y = event.locationInWindow.y - frame.minY

		xdiff = p1.x - p2.x
		ydiff = p1.y - p2.y

		//
		// This delicate logic causes: an initial mouse dragged
		// event of tiny amount will just do what mouse down would have done.
		//
		// If panning, then this does not happen
		//
		if !pan && Int(xdiff) == 0 && Int(ydiff) == 0 {
			mouseDown(with: event)
			return
		}

		pan = true
		
		if pan {
			print("Panning delta: (\(xdiff), \(ydiff))")
			if xdiff != 0 && ydiff != 0 {
				zh.pan(xdiff, ydiff)
				needsDisplay = true
				barriersNeedRebuilt = true
				cancelTweakEnergy()
			}
		}

		p1 = p2
    }

	//
	// Convert the  mouse point in the event object into world coordinates
	//
	func event_to_world(_ event: NSEvent) -> (Int, Int) {
        var m, n: Double
        var x, y: Double
		m = event.locationInWindow.x - frame.minX
		n = event.locationInWindow.y - frame.minY
		(x, y) = zh.tf.WinToWorld(m, n)
		x = floor(x+0.5)
		y = floor(y+0.5)
		return (Int(x), Int(y))
	}

    override func mouseMoved(with event: NSEvent) {
		var x: Int, y: Int
		(x, y) = event_to_world(event)
		change_cursor_cb(x, y)
    }
	
	override func rightMouseUp(with event: NSEvent) {
		if mode == MODE.VIEW {
			return;
		}
		
		moving_cell = nil
	}
	
	override func rightMouseDown(with event: NSEvent) {
		if mode == MODE.VIEW {
			return
		}

		p1.x = event.locationInWindow.x - frame.minX
		p1.y = event.locationInWindow.y - frame.minY
		p2 = p1

		if event.clickCount == 2 {
			print("Double Right Clicked!")
		}

        var j, k: Double

		(j, k) = zh.tf.WinToWorld(p1.x, p1.y)

        j = floor(j+0.5)
        k = floor(k+0.5)

		print("Right Mouse down, mode=\(rtcMode), \(event.locationInWindow) -> (\(j), \(k))")

		if rtcMode == RTC.RADIO_ACTIVE {
			do_radio_active_tracer(Int(j), Int(k))
		} else if rtcMode == RTC.THICK_BARRIER || rtcMode == RTC.THIN_BARRIER {
			determine_barrier_draw_state(Int(j), Int(k))
		} else if rtcMode == RTC.TWEAK_ENERGY {
			do_tweak_energy(Int(j), Int(k))
		} else if rtcMode == RTC.MOVE_ORGANISM {
			do_start_omove(Int(j), Int(k))
		} else if rtcMode == RTC.SET_MOUSE_POS {
			do_set_mouse_pos(Int(j), Int(k))
		}
	}
	
	var moving_cell: UnsafeMutablePointer<CELL>? = nil
	
	//
	// called when starting to move organism (x, y) is the world
	// coordinates of the organism to move
	//
	func do_start_omove(_ x: Int, _ y: Int) {
		var gt: GRID_TYPE
		var ugrid = UNIVERSE_GRID()

		if x < 0 || x >= u!.pointee.width {
			return
		}

		if y < 0 || y >= u!.pointee.height {
			return
		}

		gt = Universe_Query(u, Int32(x), Int32(y), &ugrid)
		if gt != GT_CELL {
			return
		}
		
		moving_cell = ugrid.u.cell
	}
	
	//
	// Called after do_start_omove()
	// p1 previous mouse point, p2 = current mouse point
	//
	func do_omove(_ p1: NSPoint, _ p2: NSPoint) {
		var gt: GRID_TYPE
		var ugrid = UNIVERSE_GRID()
		var fx, fy: Double
		var x, y: Int32

		if moving_cell == nil {
			return
		}

		(fx, fy) = zh.tf.WinToWorld(p2.x, p2.y)
		x = Int32(floor(fx))
		y = Int32(floor(fy))
		
		if x < 0 || x >= u!.pointee.width {
			return
		}

		if y < 0 || y >= u!.pointee.height {
			return
		}
		
		var xdiff: Int32 = 0
		var ydiff: Int32 = 0
		
		xdiff = x - moving_cell!.pointee.x
		ydiff = y - moving_cell!.pointee.y
		
		var o: UnsafeMutablePointer<ORGANISM>? = nil
		o = moving_cell!.pointee.organism
		
		var curr: UnsafeMutablePointer<CELL>? = nil
		var nx: Int32 = 0
		var ny: Int32 = 0
		var ccnt: Int = 0
		var vcnt: Int = 0

		//
		// count cells, count vacant squares for new location
		// (or my cells)
		//
		curr = o!.pointee.cells
		while curr != nil {
			nx = curr!.pointee.x + xdiff
			ny = curr!.pointee.y + ydiff
			
			if nx >= 0 && nx < u!.pointee.width
						&& ny >= 0 && ny < u!.pointee.height {
				
				gt = Universe_Query(u, nx, ny, &ugrid)
				if gt == GT_BLANK {
					vcnt += 1
				} else if gt == GT_CELL {
					if ugrid.u.cell.pointee.organism == o {
						vcnt += 1
					}
				}
			}

			ccnt += 1
			curr = curr!.pointee.next
		}
		
		if ccnt != vcnt {
			return
		}
		
		//
		// clear cells
		//
		curr = o!.pointee.cells
		while curr != nil {
			x = curr!.pointee.x
			y = curr!.pointee.y
			Grid_Clear(u, x, y)
			
			curr = curr!.pointee.next
		}

		//
		// move cells
		//
		curr = o!.pointee.cells
		while curr != nil {
			curr!.pointee.x += xdiff
			curr!.pointee.y += ydiff
			Grid_SetCell(u, curr)
			
			curr = curr!.pointee.next
		}

		needsDisplay = true
	}
	
	func do_set_mouse_pos(_ x: Int, _ y: Int) {

		if x < 0 || x >= u!.pointee.width {
			return
		}

		if y < 0 || y >= u!.pointee.height {
			return
		}
		
		if u!.pointee.mouse_x == x
			&& u!.pointee.mouse_y == y {
			Universe_ClearMouse(u)
		} else {
			Universe_SetMouse(u, Int32(x), Int32(y))
		}
				
		needsDisplay = true
	}

	//
	// if (xi,yi) lies on a barrier block, then draw state is False
	// else barrierDrawState shall be true
	//
	func determine_barrier_draw_state(_ xi: Int, _ yi: Int) {
		let x = Int32(xi)
		let y = Int32(yi)
		var ugrid = UNIVERSE_GRID()
		var gt: GRID_TYPE

		if x < 0 || x >= u!.pointee.width {
			return
		}

		if y < 0 || y >= u!.pointee.height {
			return
		}

		gt = Grid_Get(u, x, y, &ugrid)
		if gt == GT_BARRIER {
			barrierDrawState = false
		} else {
			barrierDrawState = true
		}
	}

	func do_radio_active_tracer(_ xi: Int, _ yi: Int) {
		var organism: UnsafeMutablePointer<ORGANISM>
		var spore: UnsafeMutablePointer<SPORE>
		let x = Int32(xi)
		let y = Int32(yi)
		var ugrid = UNIVERSE_GRID()
		var gt: GRID_TYPE
		
		if x < 0 || x >= u!.pointee.width {
			return
		}

		if y < 0 || y >= u!.pointee.height {
			return
		}
		
		gt = Grid_Get(u, x, y, &ugrid)
		if gt == GT_CELL {
			organism = ugrid.u.cell!.pointee.organism
			Universe_SetOrganismTracer(organism)
			needsDisplay = true

		} else if gt == GT_SPORE {
			spore = ugrid.u.spore
			Universe_SetSporeTracer(spore)
			needsDisplay = true
		}
	}
	
	//
	// if (x,y) is organic, cell, spore
	//	popup the twek energy view and wait
	// for it to be dismissed modally
	//
	func do_tweak_energy(_ xi: Int, _ yi: Int) {
		Swift.print("TWEAK")
		if tv != nil {
			cancelTweakEnergy()
		}
		//tweakView.display()
		//tv.display()
		
		var gt: GRID_TYPE
		var ugrid = UNIVERSE_GRID()
		
		var e = Int32(0)
		let x = Int32(xi)
		let y = Int32(yi)
		
		if x < 0 || x >= u!.pointee.width {
			return
		}

		if y < 0 || y >= u!.pointee.height {
			return
		}
		
		gt = Grid_Get(u, x, y, &ugrid)
		if gt == GT_CELL {
			e = ugrid.u.cell.pointee.organism.pointee.energy
		} else if gt == GT_SPORE {
			e = ugrid.u.spore.pointee.energy
			
		} else if gt == GT_ORGANIC {
			e = ugrid.u.energy
			
		} else {
			return
		}
		
		tweaking_x = x
		tweaking_y = y;
		
		var es: String
		
		es = format_comma("\(e)")
		
		//var tw = TweakView()
		var wx, wy: Double
		(wx, wy) = zh.tf.WorldToWin(Double(xi), Double(yi))
		let f: NSRect = NSMakeRect(wx, wy, 140, 21)
		tv = TweakView(frame: f)
		//tv!.wantsLayer = true
		self.addSubview(tv!)
		tv!.display()
		tv!.do_it(es, tweakEnergyDismissed)
	}
	
	//
	// set the energy of the thing at (x,y) to be 'energy'
	//
	func doTweakEnergy(_ x: Int32, _ y: Int32, _ e: Int32)
	{
		var gt: GRID_TYPE
		var ugrid = UNIVERSE_GRID()

		gt = Grid_Get(u, x, y, &ugrid)
		if gt == GT_CELL {
			ugrid.u.cell.pointee.organism.pointee.energy = e
		} else if gt == GT_SPORE {
			ugrid.u.spore.pointee.energy = e
			
		} else if gt == GT_ORGANIC {
			Grid_SetOrganic(u, x, y, e)
			
		} else {
			Swift.print("Bad (x,y) in doTweakEnergy")
		}
	}
	
	var tv: TweakView?
	var tweaking_x: Int32 = 0
	var tweaking_y: Int32 = 0
	
	func cancelTweakEnergy() {
		if tv != nil {
			tv!.go_away()
		}
	}

	func tweakEnergyDismissed(_ e: Int32, _ ok: Bool) -> Void {
		print("TweakEnergy Dismissed e=\(e), ok=\(ok)")
		tv = nil
		if ok {
			doTweakEnergy(tweaking_x, tweaking_y, e)
		}
	}
	
    override func mouseDown(with event: NSEvent){
		p1.x = event.locationInWindow.x - frame.minX
		p1.y = event.locationInWindow.y - frame.minY
		p2 = p1
		pan = false
		
        var j, k: Double

		(j, k) = zh.tf.WinToWorld(p1.x, p1.y)

        j = floor(j+0.5)
        k = floor(k+0.5)

        print("Mouse Down: \(event.locationInWindow) -> (\(j), \(k))")
		
		if event.clickCount == 2 {
			print("Double Click Detected")
		}

		if mode == MODE.VIEW {
			change_cell_cb(Int(j), Int(k))
		}
    }
	
	func select_organism(_ p: NSPoint) {
		var j, k: Double

		(j, k) = zh.tf.WinToWorld(p.x, p.y)
		j = floor(j+0.5)
		k = floor(k+0.5)

		var ugrid = UNIVERSE_GRID()
		var t: GRID_TYPE = GT_BLANK
		let x = Int32(j)
		let y = Int32(k)

		if x >= 0 && x < u!.pointee.width && y >= 0 && y < u!.pointee.height {
			t = Universe_Query(u!, x, y, &ugrid)
			if t == GT_CELL {
				Universe_SelectOrganism(u!, ugrid.u.cell.pointee.organism)
			} else {
				Universe_ClearSelectedOrganism(u!)
			}
			needsDisplay = true
			barriersNeedRebuilt = true
			cancelTweakEnergy()
		}
	}
    
    override func mouseUp(with event: NSEvent) {
        print("Mouse UP")

		if mode == MODE.VIEW {
			return
		}
		
		p2.x = event.locationInWindow.x - frame.minX
		p2.y = event.locationInWindow.y - frame.minY
		
		if !pan {
			select_organism(p1)
		}
		
		if event.clickCount == 2 {
			print("Double Click Detected, in mouseup handler")
			let y = NSDocumentController.shared.currentDocument as! Evolve5Document
			y.organismMenu(event)
		}

		p1 = p2
		pan = false
    }

	func do_pan(_ x: Double, _ y: Double) {
		zh.pan(x*100, y*100)
		needsDisplay = true
		barriersNeedRebuilt = true
	}
	
	override func keyDown(with event: NSEvent) {
		if mode == MODE.VIEW {
			return
		}

		switch(event.keyCode) {
		case 123:
			do_pan(-1, 0)		// left
			return
		case 124:
			do_pan(1, 0)		// right
			return
		case 125:
			do_pan(0, -1)		// down
			return
		case 126:
			do_pan(0, 1)		// up
			return
		case 109:
			print("F10")		// F10 - view all
			return
		case 117:
			print("Del")		// Del - delete organism
			return
	default:
			break
		}

		if event.isARepeat {
			return
		}

		let cs = event.charactersIgnoringModifiers!
		let av = cs[cs.startIndex].asciiValue
		if av != nil {
			print("Key Down \(cs) \(av!)")
			if av! >= 32 && av! <= 126 {
				Universe_SetKey(u, Int32(av!))
			}
		}
	}
	
	override func keyUp(with event: NSEvent) {
		if mode == MODE.VIEW {
			return
		}

		if tv != nil {
			// tweak energy view is showing, don't do keyboard processing
			return;
		}

		let key = event.keyCode
		print("Key Up \(key)")
		Universe_ClearKey(u!)
	}
	
	override func scrollWheel(with event: NSEvent) {
		print("Scroll \(event)")
		if event.deltaY > 0 { ZoomIn() } else { ZoomOut() }
	}
	
    func ZoomIn() {
        print("ZoomIN")
        zh.zoom_in()
		needsDisplay = true
		barriersNeedRebuilt = true
		cancelTweakEnergy()
    }
    
    func ZoomOut() {
        print("ZoomOUT")
        if zh.sp == 0 {
            return         // top level
        }
        zh.zoom_out()
		needsDisplay = true
		barriersNeedRebuilt = true
		cancelTweakEnergy()
	}
	
	func ViewAll() {
		print("ViewALL")
		zh.view_all()
		zh.set_window(0, 0, frame.width, frame.height)
		zh.resize()
		needsDisplay = true
		barriersNeedRebuilt = true
		cancelTweakEnergy()
		rebuild_tracking_area()
	}

	//
	// Re adjust the the view contain the organism
	//
	func RefocusOnOrganism(_ o: UnsafeMutablePointer<ORGANISM>) {
		assert( mode == MODE.VIEW )

		let r = organism_bounding_box(o)

		zh.set_world(r.minX, r.minY, r.maxX, r.maxY)
		zh.set_window(0, 0, frame.width, frame.height)
		zh.resize()
		rebuild_tracking_area()
		needsDisplay = true
		barriersNeedRebuilt = true
	}

	func SetCell(_ cell: UnsafeMutablePointer<CELL>) {
		self.cell = cell
		needsDisplay = true
		barriersNeedRebuilt = true
	}
	
	var radioActive = NSColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
    
    var pan: Bool = false
    override var acceptsFirstResponder: Bool { return true }
    
    var zh = ZoomHistory()
	var u = UnsafeMutablePointer<UNIVERSE>(nil)
	var cell = UnsafeMutablePointer<CELL>(nil)
	let sporeColor = NSColor.init(calibratedRed: 0.0, green: 0.749, blue: 1.0, alpha: 1.0)
	var p1 = NSPoint()
	var p2 = NSPoint()

	enum MODE {
		case MAIN	// main imulation window
		case VIEW	// view organism mode
	}
	var mode: MODE = MODE.MAIN

	public var rtcMode: RTC = RTC.NONE
	var change_cell_cb: (_ x: Int, _ y: Int) -> Void = do_nothing
	var change_cursor_cb: (_ x: Int, _ y: Int) -> Void = do_nothing
	
	var barrierLayer = CGLayer?(nil)
	public var barriersNeedRebuilt: Bool = true
	var barrierDrawState: Bool = false
}

fileprivate func do_nothing(_ x: Int, _ y: Int) {
	
}
