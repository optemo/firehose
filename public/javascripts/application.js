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
				    alert_substitute("Record has been removed.");
				},
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
			params = {"sc[product_id]" : t.siblings(".expandable_sku").attr('data-id'),
				"sc[product_type]" : t.parents(".contentholder").siblings(".edit_rule_dropdown").attr("data-pt"),
				"sc[raw]" : t.siblings(".raw").html(),
				"sc[scraping_rule_id]" : t.parents(".contentholder").siblings(".edit_rule_dropdown").attr("data-id")};
			
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
