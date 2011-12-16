
$('#save_categories').live("click",function(){
  var selected = [];
  $(':checked').each (function (index) {
      if $(this).hasClass('category_selection') {
        alert('got here');
        var id = $(this).parent().attr('id');
        alert(id);
        selected.push(id);
      }
      else {
        alert($(this).attr('class'))
      }
  });
});

$(function () {
	$("#tree_categories")
		// call `.jstree` with the options object
		.jstree({
			// the `plugins` array allows you to configure the active plugins on this instance
			"plugins" : ["themes","html_data","ui","crrm"],
			// each plugin you have included can have its own config object
			//"core" : { "initially_open" : [ "node_root" ] },
			"themes" : { "theme" : "classic" },
	
		})
		// EVENTS
		// each instance triggers its own events - to process those listen on the container
		// all events are in the `.jstree` namespace
		// so listen for `function_name`.`jstree` - you can function names from the docs
		.bind("loaded.jstree", function (event, data) {
			// you get two params - event & data - check the core docs for a detailed description
		});

   $("#tree_categories").bind("open_node.jstree", function (event, data) { 
     var id = data.rslt.obj.attr("id");
     $.ajax({
       url: "/category_ids/new",
       data: {id: id},
       success: function(data) {
         $('#' + id).replaceWith(data);
       }
       // error: function(jqXHR, textStatus, errorThrown) {
       //   alert(jqXHR.statusText);
       // }
       });
     // alert('got to open node');
  });
  
  //      // `data.rslt.obj` is the jquery extended node that was clicked
  //      alert(data.rslt.obj.attr("id"));
  //      
  // });
  
  // setTimeout(function () { $.jstree._reference("#phtml_1").open_node("#phtml_1"); }, 2500);
});