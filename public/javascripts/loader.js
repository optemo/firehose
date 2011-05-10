function opt_r(f){!!document.body?f():setTimeout('opt_r('+f+')',9)}
opt_r(function(){
var ef = document.createElement("iframe");
//Check for History
var history = location.hash.replace(/^#/, '');
var REMOTE = "http://192.168.5.100:3000";
if (history.length > 0)
	ef.src = REMOTE+"?onestage=true&hist="+history;
else
	ef.src = REMOTE+"?onestage=true";
ef.id = "optemo_iframe";
ef.width = "754px";
ef.height = "1170px";
ef.setAttribute("frameborder","0");
document.body.insertBefore(ef,document.body.firstChild);
});
function opt_s(f){/in/.test(document.readyState)?setTimeout('opt_s('+f+')',9):f()}
opt_s(function(){
	var pos = $('#optemo_embedder').offset();
	$('#optemo_iframe').css({'left': pos.left, 'top': pos.top}).show();
});