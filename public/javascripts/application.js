// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var script = document.createElement("script");
script.setAttribute("type", "text/javascript");
if (script.readyState) { 
    script.onreadystatechange = function() { if (script.readyState == "loaded" || script.readyState == "complete") { script.onreadystatechange = null; js_activator() }};
} else { 
    script.onload = function(){ js_activator() }; 
}
script.setAttribute("src", 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js');
document.getElementsByTagName("head")[0].appendChild(script);

var js_activator = (function() {
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
        $('.title_link').live('click', function() {
            // Pop up the "rule adder" in the body
            var rule_adder_div = $('<div></div>');
            rule_adder_div.attr("id", "rule_adder_div");
            
            $('body').append(rule_adder_div);
            rule_adder_div.css("top", $(window).scrollTop() + 100);
            applySilkScreen();
            rule_adder_div.load("/scraping_rules/new?rule=" + escape($(this).attr('data-location') + " -- " + $(this).attr('data-spec')), (function () {
                // The actual validation rules are according to the defaults from the jquery validation plugin, in conjunction with
                // html attribute triggers written out in views/scraping_rules/new.html.erb.
                $('#new_scraping_rule').validate({
                    rules: {
                        regexp: "regexp",
                        ifcont: "ifcont"
                    }
                });               
            }));
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
			form = $(this).parents("form");
			value = $(this).attr('Value');
            if (form.validate().valid()) { // Make sure the form is valid.
    			$.ajax({
    			    url: form.attr("action"), 
    			    data: form.serialize(), 
    				type: "POST",
    			    success: function() {
					switch(value) {
    			    	case "Update":
							window.location = "/rules";
							break;
						case "Correct":
							alert("Added correction");
							break;
						default:
							alert("Rule Created");
					}
    			  },
    				error: function() {
    			    alert("There is an error in the fields");
    			  }
    			});
			}
           	return false;
        });
		
		$("a").live('click',function(){
			t = $(this);
			if (t.attr('data-method') == "delete")
			{
				$.ajax({
					url: t.attr("href"),
					type: "DELETE",
					success: function() {
						alert("Record has been removed.");
					},
					error: function() {
						alert("Error in processing the request.");
					}
				});
				return false;
			} else {
				return true;
			}
		});
		
		$('.correction').live("click", function(){
			$(this).parents("form").find('.value').toggle().end().find('.correction_field').toggle().end().find('.correction_submit').toggle().end().find('.correction').toggle();
			return false;
		});
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
