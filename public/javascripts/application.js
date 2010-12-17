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
        flag = 0;
        // Turn on overlay links for adding rules
        $('.title_link').live('click', function() {
            // Pop up the "rule adder" in the body
            var rule_adder_div = $('<div></div>');
            rule_adder_div.attr("id", "rule_adder_div");
            $('body').append(rule_adder_div);
            applySilkScreen();
            rule_adder_div.load("/scraping_rules/new?rule=" + escape($(this).attr('data-location') + " -- " + $(this).attr('data-spec')), (function () {
               // The actual validation rules are according to the defaults from the jquery validation plugin, in conjunction with
               // html attribute triggers written out in views/scraping_rules/new.html.erb.
                $.validator.addMethod('regexp', function (possible_regexp) {
                    try {
                        g = new RegExp(possible_regexp);
                        return (Object.prototype.toString.call(g) === "[object RegExp]");
                    } catch (err) { // Not a valid regexp
                        return false;
                    }
                }, 'Please enter a valid regular expression.');

               /*
               $.validator.addMethod("email", function(value, element)
               {
                   return this.optional(element) || /^[a-zA-Z0-9._-]+@[a-zA-Z0-9-]+\.[a-zA-Z.]{2,5}$/i.test(value);
               }, "Please enter a valid email address.");

               $.validator.addMethod("username",function(value,element)
               {
                   return this.optional(element) || /^[a-zA-Z0-9._-]{3,16}$/i.test(value);
               },"Username are 3-15 characters");

               $.validator.addMethod("password",function(value,element)
               {
                   return this.optional(element) || /^[A-Za-z0-9!@#$%^&*()_]{6,16}$/i.test(value);
               },"Passwords are 6-16 characters"); */

               $('#new_scraping_rule').validate({
                   rules: {
                       regexp: "regexp",
                   }
               });               
            }));
            return false;
        });

        // Get the SKUs for each one from the category list
        $('.skus_to_fetch').each(function () {
            if (flag == 0) {
                var id = $(this).attr('data-id');
				$(this).load("/scrape/" + id, function(){
					$(this).find('.togglable').andSelf().each(function(){addtoggle($(this));});
				});
				
            }
            flag = 1;
        });

        function addtoggle(item){
			var closed = item.find("> a").click(function() {
				$(this).toggleClass("closed").toggleClass("open").siblings('div').toggle();
				return false;
			}).hasClass("closed");
			if (closed) {item.find("> div").hide();}
		}
		$('.togglable').each(function(){addtoggle($(this));});
        $('#silkscreen').click(function () {removeSilkScreen();});

        $('#scraping_rule_submit').click(function() {
			if ($(this).attr('Value') == "Update")
			{
				$.ajax({
				    url: $(this).parent().attr("action"), 
				    data: $(this).parent().serialize(), 
					type: "POST",
				    success: function() {
				    window.location = "/rules";
				  },
					error: function() {
				    alert("There is an error in the regular expression");
				  }
				});
			}
			else
				$.ajax({
				    url: "/scraping_rules/create", 
				    data: $('#new_scraping_rule').serialize(), 
					type: "POST",
				    success: function() {
				    alert("hooray");
				  }
				});
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
