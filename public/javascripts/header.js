$(document).ready(function(){
  var copy = "Find places to explore and people to guide you"
  $("#term").val(copy);
  $("#term").css({'color':'grey'});
  
  $("#term").focus(function() {
    this.value = "";
    $(this).css({'color': 'black'});
  })
  
  $("#term").blur(function() {
    if (this.value == '') {
      this.value = copy;
      $(this).css({'color':'grey'});
    }
  })
  
  var userLocation = JSON.parse($.cookie('location'));
  
  var user_lat = 49.2;
  var user_lng = -123.2;
  
  if ((typeof userLocation !== "undefined") && (userLocation !== null)) {
    if (typeof userLocation["remote_ip"] !== "undefined") {
      user_lat = parseFloat(userLocation["remote_ip"]["lat"]);
      user_lng = parseFloat(userLocation["remote_ip"]["lng"]);
    } else if (typeof userLocation["user"] !== "undefined") {
      user_lat = parseFloat(userLocation["user"]["lat"]);
      user_lng = parseFloat(userLocation["user"]["lng"]);
    } else {
      user_lat = parseFloat(userLocation["default"]["lat"]);
      user_lng = parseFloat(userLocation["default"]["lng"]);
    }
  }

    /*
  $("#term").autocomplete({
    minLength: 3,
    html: true,
    select: function(e, ui) {
      var findText = '<div class="hidden" id="url">';
      var url = ui.item.value.substring(ui.item.value.indexOf(findText)+findText.length, ui.item.value.length-6);
      window.location = url;
      return false;
    },
    focus: function(e, ui) {
      var startText = '<div class="autocomplete_name">'
      var endText = '</div><div class="autocomplete_location">'
      var name = ui.item.value.substring(ui.item.value.indexOf(startText)+startText.length, ui.item.value.indexOf(endText));
      $("#term").val(name);
      return false;
    },
    source: function(req, add) {
      var url = "/search/?lat="+user_lat+"&lng="+user_lng+"&input="+escape(req["term"]);
      
      $.getJSON(url, function(data) {
        var results = data.results;
        var suggestions = [];
        
        $.each(results, function(i, val) {
          var text = "";
          if (val["pic"]) {
            text = '<div class="autocomplete_thumb"><img class="autocomplete_thumb_img" src="'+val["pic"]+'"/></div><div class="autocomplete_thumb_holder"><div class="autocomplete_name">'+val["name"]+'</div><div class="autocomplete_location">'+val["location"]+'</div></div><div class="hidden" id="url">'+val["url"]+'</div>';
          } else {
            text = '<div class="autocomplete_holder"><div class="autocomplete_name">'+val["name"]+'</div><div class="autocomplete_location">'+val["location"]+'</div></div><div class="hidden" id="url">'+val["url"]+'</div>';
          }
          suggestions.push(text);
        });
        
        add(suggestions);
      });
    }
  });  */
  
  $("#search_submit").click(function(){
    if ($("#term").val() != "") {
      var url = "/search/?lat="+user_lat+"&lng="+user_lng+"&input="+escape($("#term").val());
      window.location = url;
      return false;
    }
  });
});
