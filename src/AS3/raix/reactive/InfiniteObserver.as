package raix.reactive
{
	import raix.reactive.scheduling.Scheduler;
	
	public class InfiniteObserver implements IObserver
	{
		public function InfiniteObserver(... args)
		{
			args.forEach(function(arg:*, ... a):void {
				if(arg is Function)
				{
					if(next == null)next = arg;
					else if(complete == null)complete = arg;
					else if(error == null)error = arg;
				}
				if(arg is IObservable)
				{
					observables.push(arg);
				}
				if(arg is Array)
				{
					observables.push.apply(null, arg);
				}
			});
			
			cancelable = subscribe(this);
		}
		
		private const observables:Array = [];
		private var cancelable:ICancelable;
		
		private var next:Function;
		private var complete:Function;
		private var error:Function;
		
		public function onNext(value:Object):void
		{
			if(next != null)
			{
				next(value);
			}
		}
		
		public function onError(e:Error):void
		{
			if(error != null)
			{
				error(e);
			}
		}
		
		public function onCompleted():void
		{
			if(complete != null)
			{
				complete();
			}
			
			cancelable.cancel();
			cancelable = subscribe(this);
		}
		
		public function dispose():void
		{
			cancelable.cancel();
			observables.length = 0;
			next = complete = error = null;
		}
		
		private function subscribe(self:IObserver):ICancelable
		{
			return new CompositeCancelable(observables.map(function(obs:IObservable, ... args):ICancelable {
				return obs.subscribeOn(Scheduler.asynchronous).subscribeWith(self);
			}));
		}
	}
}
