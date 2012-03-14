package gestures.multitouch
{
	public class ExpandData
	{
		public function ExpandData(l:TouchPoint, r:TouchPoint, delta:Number)
		{
			_left = l;
			_right = r;
			_delta = delta;
		}
		
		private var _delta:Number;
		private var _left:TouchPoint;
		private var _right:TouchPoint;
		
		public function get delta():Number
		{
			return _delta;
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