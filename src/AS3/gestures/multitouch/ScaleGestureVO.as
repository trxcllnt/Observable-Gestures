package gestures.multitouch
{
	import flash.geom.Point;
	
	public class ScaleGestureVO
	{
		public function ScaleGestureVO(l:TouchPoint, r:TouchPoint)
		{
			_left = l;
			_right = r;
		}
		
		private var _left:TouchPoint;
		private var _right:TouchPoint;
		
		public function get center():Point
		{
			return left.add(new Point(right.x - left.x >> 1, right.y - left.y >> 1));
		}
		
		public function get delta():Point
		{
			return new Point(Math.abs(left.x - right.x), Math.abs(left.y - right.y));
		}
		
		public function get left():TouchPoint
		{
			return _left;
		}
		
		public function get right():TouchPoint
		{
			return _right;
		}
	}
}
