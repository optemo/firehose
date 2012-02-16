/*
*= require_self
*= require categories
*= require layout_editor
*= require jquery.jeditable.min
*= require jquery_ujs
*= require jquery.validate.min
*= require jstree
*/

$(document).ready(function(){


    // Turn on overlay links for adding rules
    $('.title_link, .new_rule').live('click', function() {
        // Pop up the "rule adder" in the body
        var rule_adder_div = $('<div></div>');
        rule_adder_div.attr("id", "rule_adder_div");
        
        $('body').append(rule_adder_div);
        rule_adder_div.css("top", $(window).scrollTop() + 100);
        applySilkScreen();

		myparams = [];
		params = {"rule[remote_featurename]" : $(this).attr('data-rf'),
			"rule[local_featurename]" : $(this).attr('data-lf'),
			"raw" : $(this).attr('data-spec')};
		for (i in params)
		{
			if (params[i] !== undefined) {
				myparams.push(escape(i)+"="+escape(params[i]));
			}
		}
        myurl = ($(this).attr('data-url') || window.location + "/new") + "?" + myparams.join('&');

        rule_adder_div.load(myurl, (function () {
            // The actual validation rules are according to the defaults from the jquery validation plugin, in conjunction with
            // html attribute triggers written out in views/scraping_rules/new.html.erb.
            $(this).find('form').validationlidate({
                rules: {
                    regexp: "regexp",
                    ifcont: "ifcont"
                }
            });               
        }));
        return false;
    });
    
    var dropdown_function = function() {
        var t = $(this);
        var el_to_insert_after = t.next(); // The "destroy" link
        $.ajax({
            url: t.attr('href'),
		    success: function(data) {
                // Insert the editing fields directly below
		        el_to_insert_after.after(data);
			},
			error: function() {
		        alert_substitute("There is an error in fetching the form");
		    }
        });
        t.text('Hide Rule').unbind('click').click(function() {
            t.text('Edit Rule');
            el_to_insert_after.next().remove();
            t.unbind('click').click(dropdown_function);
            return false;
        });
        return false;
    };
    
    function dropdown_categories() {       
       var dropdown_div = $('#tree_categories');   
       dropdown_div.load("/category_ids/show");
       $('#header').append(dropdown_div);
       load_tree();
       return false;
    };
    
    function load_tree() {
      alert('Navigate and click on a category');
    	$("#tree_categories")
    	.bind("loaded.jstree", function (event, data) {
  			// you get two params - event & data - check the core docs ftor a detailed description
  		})
    		.jstree({
    			//"plugins" : ["themes","html_data","ui","crrm"],
    			"plugins" : ["themes","html_data"],
    			"themes" : { "theme" : "classic" },
    		});
    		// EVENTS
    		// each instance triggers its own events - to process those listen on the container
    		// all events are in the `.jstree` namespace
    		// so listen for `function_name`.`jstree` - you can function names from the docs
       $("#tree_categories").bind("open_node.jstree", function (event, data) { 
         var id = data.rslt.obj.attr("id");
         var product_type_id = $('#top_type').attr('data-id');
         $.ajax({
           url: "/category_ids/new",
           data: {id: id, product_type: product_type_id},
           success: function(data) {
             $('#' + id).replaceWith(data);
           }
           });
      });
    }
    
    $('.edit_rule_dropdown').click(dropdown_function);
    
    // $(function () {
    //   load_tree();
    // });
    
    $('#open_category_tree').click(function() {
      dropdown_categories();
      });
    
    $('.raise_rule_priority').click(function() {
        var t = $(this), form = t.parents("form");
        $.ajax({
    		url: "/scraping_rules/raisepriority?id=" + t.parent().attr("data-id"),
    		data: form.serialize(),
    		type: "POST",
    		success: function() {
    		    alert_substitute("Rule priority raised.");
    		},
    		error: function() {
    			alert_substitute("Error in processing the rule raise request.");
    		}
        });
        return false;
    });
    
    $('.edit_scraping_rule').each(function() {
        $(this).validate({
            rules: {
                regexp: "regexp"
            },
            errorPlacement: function(error, element){
                error.appendTo( element.parent());
            }
        }); 
    });

    $('.expandable_sku').live("click", function () {
		$(this).load(window.location + "/" + $(this).attr('data-id'), function(){
			$(this).find('.togglable').each(function(){addtoggle($(this));});
			$(this).removeClass('bold').removeClass('expandable_sku');
			return false;
		});
    });
    
    // Scrape the first SKU from the category list
    $('.skus_to_fetch').first().click();

    function addtoggle(item){
		var closed = item.hasClass("closed");
		if (closed) {item.siblings('div').hide();}
	}
	$('.togglable').each(function(){addtoggle($(this));});
	$('.togglable').live('click', function(){
	  $(this).toggleClass("closed").toggleClass("open").siblings('div').toggle();
		return false;
	});
    $('#silkscreen').click(function () {removeSilkScreen();});

    $('.scraping_rule_submit, .correction_submit').live("click", function() {
        var t = $(this), form = t.parents("form"), value = t.attr('Value');
        if (form.validate().valid()) { // Make sure the form is valid.
			$.ajax({
			    url: form.attr("action"), 
			    data: form.serialize(), 
				type: "POST",
			    success: function(data) {
					switch(value) {
						case "Correct":
						  //Scraping Correction
              removeSilkScreen();
              alert_substitute("Correction Processed");
							break;
						case "Update Rule":
							removeSilkScreen();
						    alert_substitute("Rule Updated");
						    ajaxhandler(data);
						    break;
						default:
						    ajaxhandler(data);
						    alert_substitute("Rule Created");
    					    removeSilkScreen();
					}
			  	},
				error: function() {
				    removeSilkScreen();
			        alert_substitute("There is an error in the fields");
			    }
			});
		}
       	return false;
    });
	
	function alert_substitute(msg) {
		var div_to_add = $("<div class='global_popup'>" + msg + "</div>");
		$("body").append(div_to_add);
		div_to_add.delay(2000).fadeOut(1000);  
    }

    $("a").live('click',function(){
      		t = $(this), form = t.parents("form");
      		
      		if (t.hasClass('catnav')) {
      		  var cat_id = t.parent().attr('id');
      		  var parts = $(location).attr('href').split('/');
      		  parts[3] = parts[3][0] + cat_id
      		  address = parts.join('/');
      		  alert("Selected to go to" + address);
      		  
      		  window.location = address;
      		  return true;
      		}
      		
      		if (t.hasClass('category_id-delete') || t.hasClass('delete_scraping_rule')) {
      		  t.parent().remove();
      		  alert_substitute("Item has been removed.");
      		  return false;
      		}
      		else if (t.attr('data-method') == "delete")
      		{
      		  if (confirm("Are you sure you want to delete this item?")) {
      			  $.ajax({
        				url: t.attr("href"),
        				data: form.serialize(),
        				type: "DELETE",
        				success: function(data) {
        				    if (t.hasClass('feature-delete') || t.hasClass('spec-delete') || t.hasClass('url-delete')) {
        					    t.parent().remove();
        					  }
        				}
        				,
        				error: function() {
        					alert_substitute("Error in processing the request for delete.");
        				}
        			});
      		  }
      			return false;
      		} else {
      			return true;
      		}
      	});
  
	
	$('.correction').live("click", function(){
		myparams = [];
		var t = $(this);
		if (t.html() === "Update Correction") {
			myurl = $("h3").attr("data-correctionsurl") + "/" + t.siblings(".parsed").attr("data-sc") + "/edit";
		}
		else {
			elem = t.parents(".contentholder").siblings(".edit_rule_dropdown"); //Single rule definition
			if (! elem.length > 0) {
				//Combined for all rules, chooses the first one as id
				elem = t.parents(".contentholder").parent().find(".edit_rule_dropdown");
			}
			params = {"sc[product_id]" : t.siblings(".expandable_sku").attr('data-id'),
				"sc[raw]" : t.siblings(".raw").attr("data-rawhash") || t.siblings(".raw").html(),
				"sc[scraping_rule_id]" : elem.attr("data-id")};
			
			for (var i in params)
			{
				if (params[i] !== undefined) {
					myparams.push(escape(i)+"="+escape(params[i]));
				}
			}
        	myurl = $("h3").attr("data-correctionsurl") + "/new?" + myparams.join('&');
		}
        t.toggle().siblings(".parsed").load(myurl);
		
		return false;
	});

    // Editable, use jeditable to edit inline. Document is jquery jeditable
    var editableVar = {
	      method: 'PUT',
	      indicator : 'Saving...',
	      tooltip : 'Click to edit...',
	      cancel : 'Cancel',
	      submit : 'Ok',
	      submitdata : function(value, settings) {
	          pName = $(this).data("name");
	          dId = $(this).data("id");
	          origin = '';
	          orgElement = '';
	          if ($(this).hasClass('stream')) {
		            orgElement = $(this).data("origin");
		            return { name : pName, dId : dId, orgElement : orgElement };
	          }
	          return { name : pName, dId : dId };
	      },
	      callback : function(value, settings) {
	          console.log(this);
	          console.log(value);
	          console.log(settings);
	          if ($(this).hasClass('stream')) {
		            if(value == '') {
		                $(this).prev('span.comma').remove();
		                $(this).remove();
		            } else
		            {
		                arr = value.split(',');
		                $(this).data('origin', arr[0]);
		                $(this).text(arr[0]);
		                for (var i=1; i<arr.length; i++) {
			                  spanElem = $("<span class='comma'>,</span>");
			                  spanNewVal = $("<span class='" +$(this).attr("class") + "' data-origin='" + arr[i] + "' data-id='" + $(this).data("id") + "' data-name='" + $(this).data("name") + "'>" + arr[i] + "</span>");
			                  spanNewVal.editable('/product_types/1', editableVar);
			                  $(this).parent().append(spanElem);
			                  $(this).parent().append(spanNewVal);
		                }
//		                $(this).data('origin', value);
		            }
	          }
	      }
    };

    $('a.show-hide').live('click', function () {

	      if($(this).hasClass("not-all")) {
	          $(this).parent().nextUntil('dt', 'dd.invisible').show();
	          $(this).text ("Hide No Value Attributes");
            $(this).removeClass("not-all");
	      } else {
	          $(this).parent().nextUntil('dt', 'dd.invisible').hide();
	          $(this).text ("Show All Attributes");
            $(this).addClass("not-all");
	      }
	return false;
	});
	
	$('.coverage_submit').live('click', function(){
	  $(this).parent().submit();
	  //$.post(location.href, {coverage: 1})
	});
	
	$('.fetch_candidates').live('click', function(){
	  var contentbox = $(this).siblings('div');
	  if(contentbox.html() == "Processing...") {
	    $.get(window.location+"/"+$(this).parent().attr('data-id'), function(data){
	      contentbox.html(data);
	    });
	  }
	});

    $(".custom_regex").live('click', function() {
	reg = $(this).parent().prev();// children('.scraping_rule_regex');
	reg_option = $(this).prev().prev().prev(); // prev('.scraping_rule_regex_option');

	if (reg.is(":visible")) {
	    reg.hide();
	    reg_option.show();
	    reg.attr('name', 'scraping_rule_option[regex]');
	    reg_option.attr('name', 'scraping_rule[regex]');

	}
	else  {
            reg.show();
	    reg_option.hide();
	    reg.attr('name', 'scraping_rule[regex]');
	    reg_option.attr('name', 'scraping_rule_option[regex]');
	}
	    
	    
	});



    // $('a.spec-delete').live('click', function () {
    // 	if (($(this).parent().next('dd.features').(':first-child').children().length > 0)) {
    // 	    alert_substitute("The heading is not empty. Can not be deleted!");
    // 	    return false;
    // 	}
    // 	});
    // $('.edit-select').editable('/product_types', {
    // 	method: 'PUT',
    // 	type: 'select',
    // 	indicator : 'Saving...',
    // 	tooltip : 'Click to edit...',
    // 	submit : 'Ok',
    // 	loadurl : '/product_types',
    // 	loaddata : function(value, settings) {
    // 	    return {foo: "bar"};
    // 	    },
    // 	submitdata : function(value, settings) {
    // 	    return {foo: "bar"};
    // 	},
    // 	callback : function(value, settings) {
    // 	    console.log(this);
    // 	    console.log(value);
    // 	    console.log(settings);
    // 	}

    // });
    
});

/* The ajax handler takes data from the ajax call and inserts the data into the #main part and then the #filtering part. */
function ajaxhandler(data) {
    var rdr;
    if (rdr = /\[REDIRECT\](.*)/.exec(data)) {
      window.location.replace(rdr[1]);
    } else {
      var parts = data.split('[BRK]');
      if (parts.length == 2) {
        $('#ajaxfilter').empty().append(parts[1]);
        $('#main').html(parts[0]);
        my.whenDOMready();
        return 0;
      }
    }
};

function removeSilkScreen() {
    $('#silkscreen').css({'display' : 'none', 'top' : '', 'left' : '', 'width' : ''}).fadeTo(0, 0).hide();
    // outsidecontainer in the other project is the pop-up window. it's rule_adder_div in this project
    $('#rule_adder_div').remove(); //css({'display' : 'none'});
//    $('#rule_adder_div').unbind('click');
}

function applySilkScreen() {
    /* This is used to get the document height for doing layout properly. */
    /*http://james.padolsey.com/javascript/get-document-height-cross-browser/*/
    current_height = (function() {
        var D = document;
        return Math.max(
            Math.max(D.body.scrollHeight, D.documentElement.scrollHeight),
            Math.max(D.body.offsetHeight, D.documentElement.offsetHeight),
            Math.max(D.body.clientHeight, D.documentElement.clientHeight)
        );
    })();
        	
	$('#silkscreen').css({'height' : current_height+'px', 'display' : 'inline'}).fadeTo(0, 0.5);
}
