
// Load a script asynchronously
function loadScript( url, callback ) {
  var script = document.createElement( "script" );
  script.type = "text/javascript";
  script.onload = function() {
    callback();
  };

  script.src = url;
  var head = document.getElementsByTagName( "head" )[0];
  head.appendChild( script );
}

function forEach(values, callback, thisArg) {
  if (values.forEach) {
    values.forEach(callback, thisArg);
  } else {
    for (var i = 0; i < values.length; i++) {
      callback.call(thisArg, values[i], i, values);
    }
  }
}

function tryEval(code) {
  var result = null;
  try {
    result = eval(code);
  } catch(error) {
    if (!error instanceof SyntaxError) {
      throw error;
    }
    try {
      result = eval("(" + code + ")");
    } catch(e) {
      if (e instanceof SyntaxError) {
        throw error;
      } else {
        throw e;
      }
    }
  }
  return result;
}

function evalAndRun(tasks, target, args) {
  if (tasks) {
    forEach(tasks, function(task) {
      var theseArgs = args;
      if (typeof(task) === "object") {
        theseArgs = theseArgs.concat([task.data]);
        task = task.code;
      }
      var taskFunc = tryEval(task);
      if (typeof(taskFunc) !== "function") {
        throw new Error("Task must be a function! Source:\\n" + task);
      }
      taskFunc.apply(target, theseArgs);
    });
  }
}

// Load any widgets
function load_async_widget_data(){
	window.setTimeout(function() {
		var bindings = window.HTMLWidgets.widgets || [];
		bindings.forEach(function(binding){

			// return("");

			var matches = binding.find(document.documentElement);
			matches.forEach(function(el){

				var page_filepath = $("header").attr("files-dir");
				var widget_filepath = page_filepath+"/widgets";
				var widget_name = el.id.replace("-", "_");

				loadScript(widget_filepath+"/"+widget_name+".js?version="+Date.now(), function(){
					var plotdata = eval(widget_name);
					var data = JSON.parse(plotdata);
					var initResult = el["htmlwidget_data_init_result"];
					// Resolve strings marked as javascript literals to objects
					if (!(data.evals instanceof Array)) data.evals = [data.evals];
					for (var k = 0; data.evals && k < data.evals.length; k++) {
						HTMLWidgets.evaluateStringMember(data.x, data.evals[k]);
					}
					binding.renderValue(el, data.x, initResult);
					evalAndRun(data.jsHooks.render, initResult, [el, data.x]);
					el.classList.remove("html-widget-unloaded");
				})

			});

		});
	}, 500);

}

// Add a post render handler
HTMLWidgets.addPostRenderHandler(load_async_widget_data);


