// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
$.ajaxSetup({
  statusCode: {
    401: function() {
      location.href = "/users/sign_in";
    }
  }
});

function fadeArrow() {
  $('#arrow_box').fadeOut(100);
  $(window).unbind('click', fadeArrow);
  $('#placemark').unbind('click', fadeArrow);
  $('.star_link').unbind('click', fadeArrow);
  $('.follow_link').unbind('click', fadeArrow);
  $('#star').unbind('click', fadeArrow);
}

function firstRun() {
  // Read the cookie and test if that element is on the page
  // If it is, update the cookie
  var status = JSON.parse($.cookie("first_run"));
  
  if (status && "value" in status && "modified" in status) {
    if (status["value"] == "search" && status["modified"] == false) {
      if ($('#term').length === 1) {
        var call_to_action = $('<div id="arrow_box" class="arrow_box"><p class="arrow_action">Let\'s put a place on your map</p><p class="arrow_more">Type the name of a place to pin</p></div>').hide();
        $('#term').after(call_to_action);
        
        var offset = $('#term').offset();
        var height = offset.top + $('#term').outerHeight(true);
        var width = offset.left + $('#term').outerWidth(true)/2 - $('#arrow_box').outerWidth(true)/2;
        
        $('#arrow_box').offset({top:height, left:width});
        $('#arrow_box').fadeIn(500);
        
        $(window).bind('click', fadeArrow);
        $("#placemark").bind('click', fadeArrow);
        $('.star_link').bind('click', fadeArrow);
        $('.follow_link').bind('click', fadeArrow);
        $('#star').bind('click', fadeArrow);
        
        status["modified"] = true;
        $.cookie('first_run', JSON.stringify(status), {path:'/'});
      }  
    } else if (status["value"] == "placemark" && status["modified"] == false) {
      if ($('#placemark').length === 1) {
        var call_to_action = $('<div id="arrow_box" class="arrow_box alt_color"><p class="arrow_action">Click Placemark It to add this location to your map</p></div>').hide();
        $('#placemark').after(call_to_action);
        
        var offset = $('#placemark').offset();
        var height = offset.top + $('#placemark').outerHeight(true) + 15;
        var width = offset.left + $('#placemark').outerWidth(true)/2 - $('#arrow_box').outerWidth(true)/2;
        
        $('#arrow_box').offset({top:height, left:width});
        $('#arrow_box').fadeIn(500);
        
        $(window).bind('click', fadeArrow);
        $("#placemark").bind('click', fadeArrow);
        $('.star_link').bind('click', fadeArrow);
        $('.follow_link').bind('click', fadeArrow);
        $('#star').bind('click', fadeArrow);
        
        status["modified"] = true;
        $.cookie('first_run', JSON.stringify(status), {path:'/'});
      }
    } else if (status["value"] == "map" && status["modified"] == false) {
      if ($('#me').length === 1) {
        var call_to_action = $('<div id="arrow_box" class="arrow_box"><p class="arrow_action">Click your name to see this place on your map</p></div>').hide();
        $('#me').after(call_to_action);

        var offset = $('#me').offset();
        var height = offset.top + $('#me').outerHeight(true) + 15;
        var width = offset.left + $('#me').outerWidth(true)/2 - $('#arrow_box').outerWidth(true)/2;
        
        $('#arrow_box').offset({top:height, left:width});
        $('#arrow_box').fadeIn(500);
        
        $(window).bind('click', fadeArrow);
        $("#placemark").bind('click', fadeArrow);
        $('.star_link').bind('click', fadeArrow);
        $('.follow_link').bind('click', fadeArrow);
        $('#star').bind('click', fadeArrow);
        
        status["modified"] = true;
        $.cookie('first_run', JSON.stringify(status), {path:'/'});
      }
    }
  }
}

function callToDownload() {
  $(document).ready(function() {
    var firstRun = JSON.parse($.cookie("first_run"));
    var firstRunBlock = false;
    if (firstRun && "value" in firstRun && "modified" in firstRun) {
      if (firstRun["value"] == "search" && firstRun["modified"] == false) {
        firstRunBlock = true;
      }
    }
    
    var show = true;
    var download = JSON.parse($.cookie("download"));
    
    if (typeof download != 'undefined') {
      show = download;
    }
    
    if (!show && !firstRunBlock) {
      setTimeout(function() {
        $("#download_container").slideDown(1000);
      }, 2000);

      $("#close").click(function(event) {
        event.preventDefault();
        $.cookie('download', JSON.stringify(true), {path:'/'});
        $("#download_container").slideUp( 1000 );
      });
    }
  });
}