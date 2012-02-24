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
		public function MouseMultitouchSimulator(stage:Stage, mouseObservables:MouseGestures, keyboardObservables:KeyboardGestures)
		{
			initialize(stage, mouseObservables, keyboardObservables);
		}
		
		[Embed(source = "touch_point_handle_32x32.png")]
		private const handleImage:Class;
		
		protected function initialize(stage:Stage, mouseObservables:MouseGestures, keyboardObservables:KeyboardGestures):void
		{
			keyboardObservables.register(mouseObservables.register(stage));
			
			mouseObservables.mouseDown(stage).
				filter(function(event:MouseEvent):Boolean {
					return !event.shiftKey && !event.altKey && !event.controlKey && !event.commandKey;
				}).
				subscribe(getHandlesAction(1, stage, mouseObservables, keyboardObservables));
			
			const shiftThenMouseDown:IObservable = keyboardObservables.keyDown(stage).
				filter(function(event:KeyboardEvent):Boolean {
					return event.keyCode == Keyboard.SHIFT;
				}).
				distinctUntilChanged(function(e1:KeyboardEvent, e2:KeyboardEvent):Boolean {
					return e1 && e2 &&
						e1.keyCode == e2.keyCode &&
						e1.shiftKey == e2.shiftKey &&
						e1.controlKey == e2.controlKey &&
						e1.commandKey == e2.commandKey;
				}).
				mapMany(function(event:KeyboardEvent):IObservable {
					return mouseObservables.mouseDown(stage);
				});
			
			shiftThenMouseDown.
				filter(function(event:MouseEvent):Boolean {
					return event.shiftKey && !event.altKey && !(event.commandKey || event.controlKey);
				}).
				subscribe(getHandlesAction(2, stage, mouseObservables, keyboardObservables));
			
			shiftThenMouseDown.
				filter(function(event:MouseEvent):Boolean {
					return event.shiftKey && !event.altKey && (event.commandKey || event.controlKey);
				}).
				subscribe(getHandlesAction(2, stage, mouseObservables, keyboardObservables, new Point(100, 0)));
			
			shiftThenMouseDown.
				filter(function(event:MouseEvent):Boolean {
					return event.shiftKey && event.altKey && !(event.commandKey || event.controlKey);
				}).
				subscribe(getHandlesAction(2, stage, mouseObservables, keyboardObservables, null, 'first'));
			
			shiftThenMouseDown.
				filter(function(event:MouseEvent):Boolean {
					return event.shiftKey && event.altKey && (event.commandKey || event.controlKey);
				}).
				subscribe(getHandlesAction(2, stage, mouseObservables, keyboardObservables, null, 'second'));
		}
		
		protected function getHandlesAction(numHandles:int,
											stage:Stage,
											mouseObservables:MouseGestures,
											keyboardObservables:KeyboardGestures,
											handleOffset:Point = null,
											moveType:String = 'opposite'):Function
		{
			handleOffset ||= new Point();
			const originalHandleOffset:Point = handleOffset.clone();
			const originalMoveType:String = moveType;
			
			return function(downEvent:MouseEvent):void {
				const shape:Shape = stage.addChild(new Shape()) as Shape;
				
				downEvent.stopImmediatePropagation();
				
				Mouse.hide();
				
				shape.graphics.clear();
				
				handleOffset = originalHandleOffset.clone();
				if(originalMoveType == 'opposite')
				{
					moveType = Keyboard.capsLock ? 'unison' : 'opposite';
				}
				
				const pos:Point = new Point(stage.mouseX, stage.mouseY);
				
				const children:Array = [];
				const handles:Array = makeHandles(numHandles).
					map(function(handle:DisplayObject, i:int, ... args):DisplayObject {
						
						const loc:Point = new Point(pos.x + (handleOffset.x * i), pos.y + (handleOffset.y * i));
						const child:InteractiveObject = toEnumerable(getObjectsUnderPoint(stage, loc)).
							lastOrDefault(stage) as InteractiveObject;
						
						children[i] = child;
						
						if(i == 0 && child is IMultitouchCompliant)
						{
							const control:InteractiveObject = IMultitouchCompliant(child).relatedControl;
							if(control)
							{
								const controlLocation:Point = control.localToGlobal(new Point(control.width * 0.5, control.height * 0.5));
								handleOffset.x = controlLocation.x - pos.x;
								handleOffset.y = controlLocation.y - pos.y;
							}
						}
						
						handle.x = loc.x - (handle.width * 0.5);
						handle.y = loc.y - (handle.height * 0.5);
						
						const e:TouchEvent = translateTouchEvent(TouchEvent.TOUCH_BEGIN,
																 downEvent, i + 1, true,
																 child.globalToLocal(loc),
																 handle, child);
						
						child.dispatchEvent(e);
						
						shape.graphics.beginFill(0xFF0000, 1);
						shape.graphics.drawCircle(e.stageX, e.stageY, 5);
						shape.graphics.endFill();
						
						return stage.addChild(handle);
					});
				
				mouseObservables.mouseMove(stage).
					takeUntil(mouseObservables.mouseUp(stage)).
					takeUntil(keyboardObservables.keyUp(stage)).
					subscribe(function(moveEvent:MouseEvent):void {
						
						moveEvent.stopImmediatePropagation();
						
						shape.graphics.clear();
						
						handles.forEach(function(handle:DisplayObject, i:int, ... args):void {
							
							if(moveType == 'second' && i == 0)
							{
								return;
							}
							else if(moveType == 'first' && i == 1)
							{
								return;
							}
							
							const w:Number = (handle.width * 0.5);
							const h:Number = (handle.height * 0.5);
							var child:InteractiveObject = children[i];
							
							handle.x += ((pos.x - stage.mouseX) * (i == 0 ? -1 : 1));
							
							if(moveType == 'unison')
								handle.y = stage.mouseY - h;
							else
								handle.y += ((pos.y - stage.mouseY) * (i == 0 ? -1 : 1));
							
							const handlePosition:Point = new Point(handle.x + w, handle.y + h);
							const newChild:InteractiveObject = toEnumerable(getObjectsUnderPoint(stage, handlePosition)).
								lastOrDefault(stage) as InteractiveObject;
							var local:Point = child.globalToLocal(handlePosition);
							
							if(newChild != child)
							{
								child.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_OUT,
																		moveEvent, i + 1, i == 0, local, handle, child));
								if(child is DisplayObjectContainer &&
									DisplayObjectContainer(child).contains(newChild) == false)
								{
									child.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_ROLL_OUT,
																			moveEvent, i + 1, i == 0, local, handle, child));
									local = newChild.globalToLocal(handlePosition);
									newChild.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_OVER,
																			   moveEvent, i + 1, i == 0, local, handle, child));
									newChild.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_ROLL_OVER,
																			   moveEvent, i + 1, i == 0, local, handle, child));
								}
								else
								{
									newChild.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_OVER,
																			   moveEvent, i + 1, i == 0, local, handle, child));
								}
								children[i] = child = newChild;
							}
							
							const e:TouchEvent = translateTouchEvent(TouchEvent.TOUCH_MOVE,
																	 moveEvent, i + 1, i == 0,
																	 handlePosition, handle, child);
							
							stage.dispatchEvent(e);
							
							shape.graphics.beginFill(0xFF0000, 1);
							shape.graphics.drawCircle(e.stageX, e.stageY, 5);
							shape.graphics.endFill();
						});
						pos.x = stage.mouseX;
						pos.y = stage.mouseY;
					},
					function():void {
						handles.forEach(function(handle:DisplayObject, i:int, ... args):void {
							const child:InteractiveObject = children[i];
							const local:Point = child.globalToLocal(new Point(handle.x + (handle.width * 0.5),
																			  handle.y + (handle.height * 0.5)));
							
							child.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_END,
																	new MouseEvent(MouseEvent.MOUSE_UP),
																	i + 1, true, local,
																	handle, child));
							
							shape.graphics.clear();
							if(stage.contains(shape))stage.removeChild(shape);
							
							if(stage.contains(handle))stage.removeChild(handle);
						});
						handles.length = 0;
						children.length = 0;
						Mouse.show();
					});
			};
		}
		
		protected function makeHandles(handleCount:int):Array
		{
			return new Array(handleCount).map(function(... args):DisplayObject {
				const image:DisplayObject = new handleImage();
				image.alpha = 0.7;
				return image;
			});
		}
		
		protected static function getObjectsUnderPoint(obj:DisplayObject, pt:Point):Array
		{
			const a:Array = [];
			
			if(obj.visible && obj.hitTestPoint(pt.x, pt.y, !(obj is Stage)))
			{
				if(obj is InteractiveObject && InteractiveObject(obj).mouseEnabled)
					a.push(obj);
				
				const doc:DisplayObjectContainer = obj as DisplayObjectContainer;
				if(doc && doc.mouseChildren && doc.numChildren)
				{
					var n:int = doc.numChildren;
					for(var i:int = 0; i < n; i++)
					{
						a.push.apply(null, getObjectsUnderPoint(doc.getChildAt(i), pt));
					}
				}
			}
			
			return a;
		}
		
		protected function translateTouchEvent(type:String,
											   event:MouseEvent,
											   id:int,
											   primary:Boolean,
											   local:Point,
											   handle:DisplayObject,
											   relatedObject:InteractiveObject):TouchEvent
		{
			return new TouchEvent(type,
								  true, true, id, primary,
								  local.x, local.y,
								  handle.width, handle.height, 1,
								  relatedObject, event.ctrlKey, event.altKey,
								  event.shiftKey, event.commandKey,
								  event.controlKey, getTimer());
		}
	}
}
