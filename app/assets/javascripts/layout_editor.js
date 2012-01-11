
$('#submit_layout').live("click",function(){
  alert('in submit function');
  ordered_filters = collect_filters();
  ordered_sorting = collect_sorting();
  ordered_compare = collect_compare();
  // post to layout_editor with all of the filters and attributes
  // Then, do the same for the sortby and compare sections
  debugger
  $.ajax({
    type: 'POST',
    url: "/layout_editor",
    data: {filter_set: ordered_filters, sorting_set: ordered_sorting, compare_set: ordered_compare},
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

$('select#new_sorting').live('change', function () {
  var selected_type = $('#new_sorting option:selected').attr('value')
  $.ajax({
    url: "/facet/new",
    data: {name: selected_type, used_for: 'sortby'},
    success: function(data) {
      alert(data);
      $('#sorting_body').append(data);
    },
    error: function(jqXHR, textStatus, errorThrown) {
      alert(jqXHR.statusText);
    }
  });
});

$('select#new_compare').live('change', function () {
  var selected_type = $('#new_compare option:selected').attr('value')
  $.ajax({
    url: "/facet/new",
    data: {name: selected_type, used_for: 'show'},
    success: function(data) {
      alert(data);
      $('#compare_body').append(data);
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
  $('.filter_box').each (function (index) {
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

function collect_sorting() {
  var ordered_filters = new Array();
  $('.sortby_box').each (function (index) {
    var type = $(this).attr('data-type');
    var dbname = $(this).attr('data-id');
    var display = $(this).attr('data-label');
    var style = $($(this).children()[2].children).val();
    //var style = $(this).children()[2].children.val();
    ordered_filters[index] = [type,dbname,display,style];
    //ordered_filters.push([dbname,display,styled]);
  });
  return ordered_filters;
}

function collect_compare() {
  var ordered_filters = new Array();
  $('.show_box').each (function (index) {
    var type = $(this).attr('data-type');
    var dbname = $(this).attr('data-id');
    var display = $(this).attr('data-label');
    ordered_filters[index] = [type,dbname,display,false];
    //ordered_filters.push([dbname,display,styled]);
  });
  return ordered_filters;
}