// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ready(function(){
    $.validator.addMethod('regexp', function (possible_regexp, element) {
        try {
            g = new RegExp(possible_regexp);
            return (Object.prototype.toString.call(g) === "[object RegExp]");
        } catch (err) { // Not a valid regexp
            return false;
        }
    }, 'Invalid regular expression.');

    $.validator.addMethod('ifcont', function (value, element) {
        if ($('#rule_rule_type_cont:checked').length)
            return /[-+]?[0-9]*\.?[0-9]+/.test(value);
        else
            return true;
    }, 'Min / Max needed');

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
        myurl = "/scraping_rules/new?" + myparams.join('&');

        rule_adder_div.load(myurl, (function () {
            // The actual validation rules are according to the defaults from the jquery validation plugin, in conjunction with
            // html attribute triggers written out in views/scraping_rules/new.html.erb.
            $(this).find('form').validate({
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
            url: "/scraping_rules/"+t.attr('data-id')+"/edit", // Get the form
		    data: null, 
			type: "GET",
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
    
    $('.edit_rule_dropdown').click(dropdown_function);
    
    $('.raise_rule_priority').click(function() {
        var t = $(this), form = t.parents("form");
        $.ajax({
    		url: "/scraping_rules/raisepriority?id=" + t.attr("data-id"),
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

    // Scrape the first SKU from the category list
    var t = $('.skus_to_fetch').first();
	t.load("/scrape/" + t.attr('data-id'), function(){
		$(this).find('.togglable').each(function(){addtoggle($(this));});
		$(this).removeClass('expandable_sku');
	});

    $('.expandable_sku').live("click", function () {
		$(this).load("/scrape/" + $(this).attr('data-id'), function(){
			$(this).find('.togglable').each(function(){addtoggle($(this));});
			$(this).removeClass('bold').removeClass('expandable_sku');
			return false;
		});
    });

    function addtoggle(item){
		var closed = item.click(function() {
			$(this).toggleClass("closed").toggleClass("open").siblings('div').toggle();
			return false;
		}).hasClass("closed");
		if (closed) {item.siblings('div').hide();}
	}
	$('.togglable').each(function(){addtoggle($(this));});
    $('#silkscreen').click(function () {removeSilkScreen();});

    $('#scraping_rule_submit, .correction_submit').live("click", function() {
        var t = $(this), form = t.parents("form"), value = t.attr('Value');
        if (form.validate().valid()) { // Make sure the form is valid.
			$.ajax({
			    url: form.attr("action"), 
			    data: form.serialize(), 
				type: "POST",
			    success: function() {
					switch(value) {
						case "Correct":
						    removeSilkScreen();
                	        alert_substitute("Correction Processed");
							break;
						case "Update Rule":
							removeSilkScreen();
						    alert_substitute("Rule Updated");
						    break;
						default:
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
		if (t.attr('data-method') == "delete")
		{
			$.ajax({
				url: t.attr("href"),
				data: form.serialize(),
				type: "DELETE",
				success: function() {
				    if (t.hasClass('feature-delete') || t.hasClass('spec-delete') || t.hasClass('url-delete') || t.hasClass('category_id-delete')) {
					t.parent().nextUntil('dt', 'dd').remove();
					t.parent().remove();
					if(t.hasClass('feature-delete'))
					    alert_substitute("Feature has been removed.");
					if(t.hasClass('heading-delete'))
					    alert_substitute("Heading has been removed.");
					if(t.hasClass('url-delete'))
					    alert_substitute("URL has been removed.");
					if(t.hasClass('url-delete'))
					    alert_substitute("Category Id has been removed.");

					}
				    else
					alert_substitute("Record has been removed.");
				}
				    
				,
				error: function() {
					alert_substitute("Error in processing the request.");
				}
			});
			return false;
		} else {
			return true;
		}
	});
	
	$('.correction').live("click", function(){
		myparams = [];
		var t = $(this);
		if (t.html() === "Update Correction") {
			myurl = "/scraping_corrections/" + t.siblings(".parsed").attr("data-sc") + "/edit";
		}
		else {
			elem = t.parents(".contentholder").siblings(".edit_rule_dropdown"); //Single rule definition
			if (! elem.length > 0) {
				//Combined for all rules, chooses the first one as id
				elem = t.parents(".contentholder").parent().find(".edit_rule_dropdown");
			}
			params = {"sc[product_id]" : t.siblings(".expandable_sku").attr('data-id'),
				"sc[product_type]" : elem.attr("data-pt"),
				"sc[raw]" : t.siblings(".raw").attr("data-rawhash") || t.siblings(".raw").html(),
				"sc[scraping_rule_id]" : elem.attr("data-id")};
			
			for (var i in params)
			{
				if (params[i] !== undefined) {
					myparams.push(escape(i)+"="+escape(params[i]));
				}
			}
        	myurl = "/scraping_corrections/new?" + myparams.join('&');
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
    
    $('.edit, .edit-select').editable('/product_types/1', editableVar);

     $('.edit-select-bool').editable('/product_types/1', $.extend({},editableVar,{
        data : "{true: 'Yes', false: 'No'}",
        type : 'select'
    }));
    $('.edit-select-feature-type').editable('/product_types/1', $.extend({}, editableVar, {
        data : "{'Categorical': 'Categorical', 'Binary': 'Binary', 'Continuous':'Continuous'}",
        type : 'select'
    }));
    $('.edit-int').editable('/product_types/1', $.extend({},editableVar,{
        onsubmit: function(settings, form) {
            var input = $(form).find('input');
            var original = input.val();
            if (original == null || !original.toString().match(/^\d+$/)) {
                alert("Invalid input. Please input valid number!");
                return false;
            }
                
        }
    }));

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

    $('select#type_filter').live('change', function () {
	$('#filter_form').submit();
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
