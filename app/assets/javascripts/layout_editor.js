
$('#submit_layout').live("click",function(){
  ordered_filters = collect_attributes('.filter_box');
  ordered_sorting = collect_attributes('.sortby_box');
  ordered_compare = collect_attributes('.show_box');
  $.ajax({
    type: 'POST',
    url: "/layout_editor",
    data: {filter_set: ordered_filters, sorting_set: ordered_sorting, compare_set: ordered_compare},
    success: function(data) {
      alert("Finished saving layout");
    },
    error: function(jqXHR, textStatus, errorThrown) {
      alert(jqXHR.statusText + " in saving layout");
    }
  });
});

$('.remove_facet').live("click",function(){
  var facet_element = $(this).parent();
  facet_element.remove();
});

$('select#new_filter').live('change', function () {
  var selected_type = $('#new_filter option:selected').attr('value');
  // check that the name is not already present in the page
  if (jQuery.inArray(selected_type, collect_existing('.filter_box')) > -1) {
    alert('Element already exists in the layout');
  }
  else {
    $.ajax({
      url: "/facet/new",
      data: {name: selected_type, used_for: 'filter'},
      success: function(data) {
        $('#filters_body').append(data);
      },
      error: function(jqXHR, textStatus, errorThrown) {
        alert(jqXHR.statusText + " in adding facet");
      }
    });
  }
});

$('select#new_sorting').live('change', function () {
  var selected_type = $('#new_sorting option:selected').attr('value');
  $.ajax({
    url: "/facet/new",
    data: {name: selected_type, used_for: 'sortby'},
    success: function(data) {
      $('#sorting_body').append(data);
    },
    error: function(jqXHR, textStatus, errorThrown) {
      alert(jqXHR.statusText + " in adding facet");
    }
  });
});

$('select#new_compare').live('change', function () {
  var selected_type = $('#new_compare option:selected').attr('value');
  // check that the name is not already present in the page
  if (jQuery.inArray(selected_type, collect_existing('.show_box')) > -1) {
    alert('Element already exists in the layout');
  }
  else {
    $.ajax({
      url: "/facet/new",
      data: {name: selected_type, used_for: 'show'},
      success: function(data) {
        $('#compare_body').append(data);
      },
      error: function(jqXHR, textStatus, errorThrown) {
        alert(jqXHR.statusText + " in adding facet");
      }
    });
  }
});

$('#add_header').live("click",function() {
  $.ajax({
    url: "/facet/new",
    data: {type: 'Heading', used_for: 'filter'},
    success: function(data) {
      $('#filters_body').append(data);
    },
    error: function(jqXHR, textStatus, errorThrown) {
      alert(jqXHR.statusText);
    }
  });
});
$('#add_spacer').live("click",function() {
  $.ajax({
    url: "/facet/new",
    data: {type: 'Spacer', used_for: 'filter'},
    success: function(data) {
      $('#filters_body').append(data);
    },
    error: function(jqXHR, textStatus, errorThrown) {
      alert(jqXHR.statusText);
    }
  });
});

function collect_attributes(element_class) {
  var ordered_facets = new Array();
  $(element_class).each (function (index) {
    var type = $(this).attr('data-type');
    var dbname = $(this).attr('data-id');
    var display = $(this).attr('data-label');
    var styled = false;
    if (element_class == '.filter_box') {
      var kids = $(this).children();
      if (kids) {
        styled = kids.children().first().is(':checked');
      }
    }
    else if (element_class == '.sortby_box') {
      styled = $($(this).children()[2].children).val();
    }
    ordered_facets[index] = [type,dbname,display,styled];
    });
  return ordered_facets;
}

function collect_names(element_class) {
  var ordered_results = [];
  $(element_class).each (function (index) {
    ordered_results.push($(this).attr('data-id'););
  });
  return ordered_results;
}