function r(f){!!document.body?f():setTimeout('r('+f+')',9)}
r(function(){
var ef = document.createElement("iframe");
ef.src = "http://bbembed.optemo.com?embedding=true&iframe=true";
ef.id = "optemo_iframe";
ef.width = "754px";
ef.height = "1070px";
ef.setAttribute("style", "border:none;position:absolute;left:76.6px;top:60px;");
//document.getElementById("optemo_embedder").appendChild(ef);
//document.body.appendChild(ef);
document.body.insertBefore(ef,document.body.firstChild);
});
function rr(f){/in/.test(document.readyState)?setTimeout('rr('+f+')',9):f()}
rr(function(){
	var pos = $('#optemo_embedder').offset();
	$('#optemo_iframe').css({'left': pos.left, 'top': pos.top}).show();
});