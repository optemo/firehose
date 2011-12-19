
$('#submit_type').live("click",function(){
  if ($('#product_type_name').valid()) {
    var name = $('#product_type_name').attr('value');
    var categories = get_selected();
    $.ajax({
      type: 'POST',
      url: "/product_types",
      data: {name: name, categories: categories},
      success: function(data) {
        location.replace('/product_types');
        //$('body').html(data);
      },
      error: function(jqXHR, textStatus, errorThrown) {
        alert(jqXHR.statusText + " in submitting");
      }
    });
  }
});

$('#save_type').live("click",function(){
  var pid = $('#top_type').attr('data-id');
  var categories = get_selected();
  $.ajax({
    type: 'PUT',
    url: "/product_types/" + pid,
    data: {categories: categories, id: pid},
    success: function(data) {
      alert("Finished submitting product type");
      location.replace('/product_types');
    },
    error: function(jqXHR, textStatus, errorThrown) {
      alert(jqXHR.statusText + " in submitting");
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
     var product_type_id = $('#top_type').attr('data-id');
     debugger
     $.ajax({
       url: "/category_ids/new",
       data: {id: id, product_type: product_type_id},
       success: function(data) {
         $('#' + id).replaceWith(data);
       }
       // error: function(jqXHR, textStatus, errorThrown) {
       //   alert(jqXHR.statusText);
       // }
       });
     // alert('got to open node');
  });

});

function get_selected(){
  var selected = [];
  $(':checked').each (function (index) {
      if ($(this).hasClass('category_selection')) {
        var id = $(this).parent().attr('id');
        var name = $(this).parent().attr('data-name');
        selected.push([id, name]);
      }
  });
  return selected;
}