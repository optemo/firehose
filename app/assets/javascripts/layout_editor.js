
$('#submit_layout').live("click",function(){
  // collect all the filters, each with its attributes, checked bokes, etc.
  ordered_filters = collect_filters();
  
  // post to layout_editor with all of the filters and attributes
  // Then, do the same for the sortby and compare sections

  // if ($(".hero_box").length == 0) {
  //     alert("Invalid input set: no hero product specified!");
  //     return false;
  //   }
  //   type = $("#title").attr('data-type');
  //   skus = collect_featured_skus();
  //   if (confirm("Confirm submitting " + skus.length + " products immediately")) {
  $.ajax({
    type: 'POST',
    url: "/layout_editor",
    data: {filter_set: ordered_filters},
    success: function(data) {
      alert("Finished saving layout");
    },
    error: function(jqXHR, textStatus, errorThrown) {
      alert(jqXHR.statusText + " in submitting layout");
    }
  });
  //   }
});

$('.remove_facet').live("click",function(){
  var facet_element = $(this).parent();
  facet_element.remove();
});

$('select#new_filter').live('change', function () {
  var selected_type = $('#new_filter option:selected').attr('value')
  alert(selected_type);
  $.ajax({
    url: "/facet/new",
    data: {name: selected_type, used_for: 'filter'},
    success: function(data) {
      alert(data);
      $('#filters_body').append(data);
    },
    error: function(jqXHR, textStatus, errorThrown) {
      alert(jqXHR.statusText);
    }
  });
});

// clicking to add a new "Header" or "Spacer"
$('#add_header').live("click",function() {
  
  $.ajax({
    url: "/facet/new",
    data: {type: 'Heading', used_for: 'filter'},
    success: function(data) {
      alert(data);
      $('#filters_body').append(data);
    },
    error: function(jqXHR, textStatus, errorThrown) {
      alert(jqXHR.statusText);
    }
  });
});
$('#add_spacer').live("click",function() {
  alert('adding spacer');
  $.ajax({
    url: "/facet/new",
    data: {type: 'Spacer', used_for: 'filter'},
    success: function(data) {
      alert(data);
      $('#filters_body').append(data);
    },
    error: function(jqXHR, textStatus, errorThrown) {
      alert(jqXHR.statusText);
    }
  });
});

function collect_filters() {
  var ordered_filters = new Array();
  $('.facetbox').each (function (index) {
    var type = $(this).attr('data-type');
    var dbname = $(this).attr('data-id');
    var display = $(this).attr('data-label');
    var styled = false;
    var kids = $(this).children();
    if (kids) {
      styled = kids.children().first().is(':checked');
    }
    ordered_filters[index] = [type,dbname,display,styled];
    //ordered_filters.push([dbname,display,styled]);
  });
  return ordered_filters;
}