//
// ZoomHistory
//

import Foundation

class ZoomHistory
{
	var tf = TF_TRANSFORM()
    var win = TF_RECT()		// aspect ratio adjusted window viewport
    var window = TF_RECT()		// actual window viewport
    var world = TF_RECT()
	let LEN = Int(100)		// zoom history length
    var sp: Int
    var stack: Array<TF_TRANSFORM>

	init() {
        sp = 0
        stack = Array<TF_TRANSFORM>(repeating: TF_TRANSFORM(), count: LEN)
	}

	func set_world(_ u: UnsafeMutablePointer<UNIVERSE>)
	{
		world.left	= 0.0 - 0.5
		world.right	= Double(u.pointee.width) + 0.5
		world.top	= 0.0 - 0.5
		world.bottom	= Double(u.pointee.height) + 0.5
	}

	func set_world(_ left: Double, _ top: Double, _ right: Double, _ bottom: Double)
	{
		world.left	= left - 0.5
		world.right	= right + 0.5
		world.top	= top - 0.5
		world.bottom = bottom + 0.5
	}

	func set_world(_ rect: TF_RECT)
	{
		world.left	= rect.left - 0.5
		world.right	= rect.right + 0.5
		world.top	= rect.top - 0.5
		world.bottom = rect.bottom + 0.5
	}

    func set_window(_ left: Double, _ top: Double, _ right: Double, _ bottom: Double)
	{
		win.left	= left
		win.top		= top
		win.right	= right
		win.bottom	= bottom

		window = win

		preserve_aspect_ratio()
	}

    func set_window(_ rect: TF_RECT)
	{
		win.left	= rect.left
		win.top		= rect.top
		win.right	= rect.right
		win.bottom	= rect.bottom

		window = win

		preserve_aspect_ratio()
	}

	func resize()
	{
		preserve_aspect_ratio()
		tf = TF_TRANSFORM(win, world)
		stack[sp] = tf
	}

	func view_all()
	{
		sp = 0
		tf = stack[ sp ]

		world = tf.world
		win = tf.win
	}

	/*
	 * Zoom in, but when no drag rectangle was specified
	 *
	 */
	func zoom_in() {
		var w, h: Double
		var rect = TF_RECT()

		/*
		 * Create 'rect' as a 1/4 smaller rectangle inside of
		 * 'window'.
		 */
		w = (win.right - win.left) / 10.0  // KJS was 8
		h = (win.bottom - win.top) / 10.0  // KJS was 8
 
		rect.left	= floor(win.left  + w)
		rect.top	= floor(win.top	   + h)
		rect.right	= floor(win.right  - w)
		rect.bottom	= floor(win.bottom - h)

		zoom_in(rect)
	}

	func zoom_in(_ rect: TF_RECT) {
		var zr = TF_RECT()
        var wr = TF_RECT()

		if sp+1 >= 100 {
			return
		}

		if rect.right >= rect.left {
			zr.left = rect.left
			zr.right = rect.right
		} else {
			zr.left = rect.right
			zr.right = rect.left
		}

		if rect.bottom >= rect.top {
			zr.top = rect.top
			zr.bottom = rect.bottom
		} else {
			zr.top = rect.bottom
			zr.bottom = rect.top
		}

		(wr.left, wr.top) = tf.WinToWorld(zr.left, zr.top)
		(wr.right, wr.bottom) = tf.WinToWorld(zr.right, zr.bottom)

		sp += 1
		tf = stack[ sp ]

		world = wr
		preserve_aspect_ratio()
		tf = TF_TRANSFORM(win, world)
		stack[sp] = tf
		pan(0, 0)
	}

	/*
	 * If we are popping the last transform, then
	 * restore that view. Otherwise pan the old view to be
	 * centered to where the window is currently viewing.
	 *
	 */
	func zoom_out() {
		var ax, ay: Double
		var bx, by: Double
		var cx, cy: Double

		if sp == 1 {
			/*
			 * restore to top-level view (show all)
			 */
			sp -= 1
			tf = stack[ sp ]
			world = tf.world
			win = tf.win

		} else if sp > 1  {
			/*
			 * restore previous view, but pan to be centered where
			 * the we are currently positioned.
			 */

			ax = (world.right + world.left)/2.0
			ay = (world.bottom + world.top)/2.0

			sp -= 1
			tf = stack[ sp ]
			world = tf.world
			win = tf.win

			bx = (world.right + world.left)/2.0
			by = (world.bottom + world.top)/2.0

			cx = ax - bx
			cy = ay - by

			world.left	+= cx
			world.top	+= cy
			world.right	+= cx
			world.bottom += cy
			tf = TF_TRANSFORM(win, world)
			stack[sp] = tf
		}
	}

	/*
	 * Pan display. (cx, cy) are values in window units
	 */
	func pan(_ cx: Double, _ cy: Double) {
		var tmp_win = TF_RECT()
		var new_world = TF_RECT()

		tmp_win = win

		tmp_win.left	+= cx
		tmp_win.top		+= cy
		tmp_win.right	+= cx
		tmp_win.bottom	+= cy

		(new_world.left, new_world.top) = tf.WinToWorld(tmp_win.left, tmp_win.top)
		(new_world.right, new_world.bottom) = tf.WinToWorld(tmp_win.right, tmp_win.bottom)

		world = new_world

		tf = TF_TRANSFORM(win, world)
		stack[sp] = tf
	}

	/*
	 * Change 'win' so its aspect ration matches the aspect ratio
	 * of the 'world' rectangle.
	 *
	 */
	func preserve_aspect_ratio() {
		var window_ratio: Double
		var world_ratio: Double

		window_ratio = (win.bottom - win.top) / (win.right - win.left)
		world_ratio = (world.bottom - world.top) / (world.right - world.left)

		if world_ratio > window_ratio {
			win.right = win.left +
					(win.bottom - win.top) / world_ratio
		} else {
			win.bottom = win.top +
					(win.right - win.left) * world_ratio
		}
	}

}
