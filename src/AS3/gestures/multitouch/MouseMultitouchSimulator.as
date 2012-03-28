package gestures.multitouch
{
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.ui.*;
	import flash.utils.*;
	
	import raix.interactive.*;
	import raix.reactive.*;
	
	public class MouseMultitouchSimulator
	{
		public function MouseMultitouchSimulator(stage:Stage)
		{
			// If there's not at least one listener for these events,
			// the Flash Player doesn't correctly calculate the stageX
			// and stageY of dispatched TouchEvents.
			const nullListener:Function = function(... args):void {};
			stage.addEventListener(TouchEvent.TOUCH_BEGIN, nullListener);
			stage.addEventListener(TouchEvent.TOUCH_END, nullListener);
			stage.addEventListener(TouchEvent.TOUCH_MOVE, nullListener);
			stage.addEventListener(TouchEvent.TOUCH_OUT, nullListener);
			stage.addEventListener(TouchEvent.TOUCH_OVER, nullListener);
			stage.addEventListener(TouchEvent.TOUCH_ROLL_OUT, nullListener);
			stage.addEventListener(TouchEvent.TOUCH_ROLL_OVER, nullListener);
			stage.addEventListener(TouchEvent.TOUCH_TAP, nullListener);
			
			this.stage = stage;
			
			initialize(stage);
		}
		
		protected var stage:Stage;
		
		[Embed(source = "touch_point_handle_32x32.png")]
		private const handleImage:Class;
		
		protected function initialize(stage:Stage):void
		{
			const mouseDown:IObservable = Observable.fromEvent(stage, MouseEvent.MOUSE_DOWN);
			const mouseUp:IObservable = Observable.fromEvent(stage, MouseEvent.MOUSE_UP);
			const mouseMove:IObservable = Observable.fromEvent(stage, MouseEvent.MOUSE_MOVE);
			const keyDown:IObservable = Observable.fromEvent(stage, KeyboardEvent.KEY_DOWN);
			const keyUp:IObservable = Observable.fromEvent(stage, KeyboardEvent.KEY_UP);
			
			const realHandle:Handle = new Handle(new handleImage());
			const mockHandle:Handle = new Handle(new handleImage());
			const center:Point = new Point();
			
			var control:Boolean = false;
			var multi:Boolean = false;
			var moved:Boolean = false;
			var down:Boolean = false;
			
			var beginTimeout:int = -1;
			
			const mouseObservable:IObservable = mouseMove.
				merge(mouseDown).
				takeUntil(mouseUp);
			
			const mouseObserver:IObserver = Observer.create(function(event:MouseEvent):void {
				
				if(realHandle.parent == null)
				{
					stage.addChild(realHandle);
				}
				
				const x:Number = event.stageX;
				const y:Number = event.stageY;
				
				if(!moved)
				{
					realHandle.id = Math.round(Math.random() * 1000);
				}
				
				moved = true;
				
				if(multi)
				{
					if(control)
					{
						mockHandle.x += x - realHandle.x - (mockHandle.width >> 1);
						mockHandle.y += y - realHandle.y - (mockHandle.height >> 1);
						
						center.x = x + ((mockHandle.x - realHandle.x) >> 1);
						center.y = y + ((mockHandle.y - realHandle.y) >> 1);
					}
					else
					{
						mockHandle.x = (2 * center.x) - x - (mockHandle.width >> 1);
						mockHandle.y = (2 * center.y) - y - (mockHandle.height >> 1);
					}
				}
				
				realHandle.x = x - (realHandle.width >> 1);
				realHandle.y = y - (realHandle.height >> 1);
				
				if(event.type == MouseEvent.MOUSE_DOWN)
				{
					down = true;
					
					beginTimeout = setTimeout(function():void {
						dispatchBeginEvent(realHandle);
						
						if(multi)
						{
							dispatchBeginEvent(mockHandle);
						}
						
						clearTimeout(beginTimeout);
						beginTimeout = -1;
					
					}, 75);
				}
				else if(down)
				{
					if(beginTimeout > -1)
					{
						clearTimeout(beginTimeout);
						beginTimeout = -1;
						
						dispatchBeginEvent(realHandle);
						
						if(multi)
						{
							dispatchBeginEvent(mockHandle);
						}
					}
					
					dispatchMoveEvent(realHandle);
					
					if(multi && mockHandle.target)
					{
						dispatchMoveEvent(mockHandle);
					}
				}
				
				realHandle.alpha = down ? 1 : 0.5;
				mockHandle.alpha = down ? 1 : 0.5;
			},
			function():void {
				if(down)
				{
					const realHandleLoc:Point = new Point(realHandle.x + (realHandle.width >> 1),
														  realHandle.y + (realHandle.height >> 1));
					
					if(beginTimeout > -1)
					{
						clearTimeout(beginTimeout);
						beginTimeout = -1;
						
						dispatchTapEvent(realHandle);
						
						if(multi)
						{
							dispatchTapEvent(mockHandle);
						}
					}
					else
					{
						dispatchEndEvent(realHandle);
						
						if(multi && mockHandle.target)
						{
							dispatchEndEvent(mockHandle);
						}
					}
				}
				
				realHandle.id = 0;
				realHandle.target = null;
				
				realHandle.alpha = 0.5;
				mockHandle.alpha = 0.5;
				
				moved = false;
				down = false;
				
				mouseObservable.subscribeWith(mouseObserver);
			});
			
			mouseObservable.subscribeWith(mouseObserver);
			
			const keyboardObservable:IObservable = keyDown.filter(function(event:KeyboardEvent):Boolean {
				return event.keyCode == Keyboard.SHIFT;
			}).
			mapMany(function(... args):IObservable {
				multi = true;
				
				stage.addChild(mockHandle);
				
				center.x = stage.mouseX;
				center.y = stage.mouseY;
				
				moved = false;
				mockHandle.id = Math.round(Math.random() * 1000) + 1;
				
				mockHandle.x = center.x - (mockHandle.width >> 1);
				mockHandle.y = center.y - (mockHandle.height >> 1);
				
				return Observable.merge([
										keyDown.filter(function(event:KeyboardEvent):Boolean {
											return event.keyCode == Keyboard.CONTROL || event.keyCode == Keyboard.COMMAND;
										}).
										peek(function(... args):void {
											control = true;
										}),
										keyUp.filter(function(event:KeyboardEvent):Boolean {
											return event.keyCode == Keyboard.CONTROL || event.keyCode == Keyboard.COMMAND;
										}).
										peek(function(... args):void {
											control = false;
										})]);
			}).
			takeUntil(keyUp.filter(function(event:KeyboardEvent):Boolean {
				return event.keyCode == Keyboard.SHIFT;
			}));
			
			const keyboardObserver:IObserver = Observer.create(null, function():void {
				
				center.x = 0;
				center.y = 0;
				multi = false;
				
				mockHandle.id = 0;
				mockHandle.target = null;
				
				if(mockHandle.parent)mockHandle.parent.removeChild(mockHandle);
				
				keyboardObservable.subscribeWith(keyboardObserver);
			});
			
			keyboardObservable.subscribeWith(keyboardObserver);
		}
		
		protected function getObjectsUnderPoint(parent:DisplayObject, location:Point):Array
		{
			const a:Array = [];
			if(parent.visible && parent.hitTestPoint(location.x, location.y, !(parent is Stage)))
			{
				if(parent is InteractiveObject && InteractiveObject(parent).mouseEnabled)
				{
					a.push(parent);
					
					const doc:DisplayObjectContainer = parent as DisplayObjectContainer;
					if(doc && doc.mouseChildren && doc.numChildren)
					{
						const n:int = doc.numChildren;
						for(var i:int = 0; i < n; ++i)
						{
							a.push.apply(null, getObjectsUnderPoint(doc.getChildAt(i), location));
						}
					}
				}
			}
			
			return a;
		}
		
		protected function dispatchBeginEvent(handle:Handle):void
		{
			const handleLoc:Point = new Point(handle.x + (handle.width >> 1), handle.y + (handle.height >> 1));
			handle.target = getObjectsUnderPoint(stage, handleLoc).pop() || stage;
			handle.target.dispatchEvent(createTouchEvent(TouchEvent.TOUCH_BEGIN,
														 handle.id, true,
														 handle.target.globalToLocal(handleLoc),
														 handle, handle.target));
		}
		
		protected function dispatchMoveEvent(handle:Handle):void
		{
			const handleLoc:Point = new Point(handle.x + (handle.width >> 1), handle.y + (handle.height >> 1));
			const target:InteractiveObject = getObjectsUnderPoint(stage, handleLoc).pop() || stage;
			
			if(handle.target != target)
			{
				handle.target.dispatchEvent(createTouchEvent(TouchEvent.TOUCH_OUT,
															 handle.id, true,
															 handle.target.globalToLocal(handleLoc),
															 handle, handle.target));
				handle.target = target;
				handle.target.dispatchEvent(createTouchEvent(TouchEvent.TOUCH_OVER,
															 handle.id, true,
															 handle.target.globalToLocal(handleLoc),
															 handle, handle.target));
			}
			
			handle.target.dispatchEvent(createTouchEvent(TouchEvent.TOUCH_MOVE,
														 handle.id, true,
														 handle.target.globalToLocal(handleLoc),
														 handle, handle.target));
		}
		
		protected function dispatchEndEvent(handle:Handle):void
		{
			const handleLoc:Point = new Point(handle.x + (handle.width >> 1), handle.y + (handle.height >> 1));
			handle.target.dispatchEvent(createTouchEvent(TouchEvent.TOUCH_END,
														 handle.id, true,
														 handle.target.globalToLocal(handleLoc),
														 handle, handle.target));
		}
		
		protected function dispatchTapEvent(handle:Handle):void
		{
			const handleLoc:Point = new Point(handle.x + (handle.width >> 1), handle.y + (handle.height >> 1));
			handle.target = getObjectsUnderPoint(stage, handleLoc).pop() || stage;
			handle.target.dispatchEvent(createTouchEvent(TouchEvent.TOUCH_TAP,
														 handle.id, true,
														 handle.target.globalToLocal(handleLoc),
														 handle, handle.target));
		}
		
		protected function createTouchEvent(type:String,
											id:int,
											primary:Boolean,
											local:Point,
											handle:DisplayObject,
											relatedObject:InteractiveObject):TouchEvent
		{
			return new TouchEvent(type,
								  true, false, id, primary,
								  local.x, local.y,
								  handle.width, handle.height, 1,
								  relatedObject,
								  false, false, false, false, false,
								  getTimer());
		}
	}
}
import flash.display.*;
import flash.events.*;

internal class Handle extends Sprite
{
	public function Handle(child:DisplayObject)
	{
		mouseEnabled = false;
		mouseChildren = false;
		addChild(child);
	}
	
	public var target:InteractiveObject;
	public var id:int = 0;
}
