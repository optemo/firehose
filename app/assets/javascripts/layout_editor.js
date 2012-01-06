
$('select#new_filter').live('change', function () {
  var selected_type = $('#new_filter option:selected').attr('value')
  alert(selected_type);
  $('#filters_body').append("<h3>new code</h3");
  update_dropdown();
});

function update_dropdown() {
  var in_page = collect_filters();
  $('.filter_option').each (function (index) {
    if (jQuery.inArray($(this).attr('value'), in_page) >= 0) {
      $(this).remove();
    }
  });
}

function collect_filters() {
  var ordered_filters = [];
  $('.facetbox').each (function (index) {
    ordered_filters.push($(this).attr('data-id'));
  });
  return ordered_filters;
}

// function collect_dropdown() {
//   var inorder_dropdown = [];
//   $('.filter_option').each (function (index) {
//     inorder_dropdown.push($(this).attr('value'));
//   });
//   return inorder_dropdown;
// }