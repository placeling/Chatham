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

function greedyFactor(base, counter) {
  var factored = [];
  var factor = Math.floor(base / counter);
  var remainder = base - counter;
  for (var i=0; i<counter; i++) {
    factored[i] = factor;
  }

  if (remainder > 0) {
    for (var i=factored.length; i>remainder; i--) {
      factored[i-1] += 1;
    }
  }
  return factored
}

function shuffle(array) {
    var tmp, current, top = array.length;

    if(top) while(--top) {
        current = Math.floor(Math.random() * (top + 1));
        tmp = array[current];
        array[current] = array[top];
        array[top] = tmp;
    }

    return array;
}

function mosaic(imageSection) {
  var columnCount = 3;
  var columnWidth = $(imageSection).width()/columnCount;
  var columnHeight = 150;
  
  var picCount = $("img", imageSection).length;
  var resizeType = [];
  
  for (var counter=0; counter < picCount; counter += columnCount) {
    var segmentResize = [];
    var numPicsInIteration = 0
    if ((picCount - counter) > columnCount) {
      numPicsInIteration = columnCount;
    } else {
      numPicsInIteration = picCount - counter;
    }
    
    if ((columnCount === numPicsInIteration) && (Math.random() < 0.2)) {
      segmentResize = greedyFactor(columnCount, numPicsInIteration-1);
    } else {
      segmentResize = greedyFactor(columnCount, numPicsInIteration);
    }
    
    segmentResize = shuffle(segmentResize);
    
    if (columnCount === numPicsInIteration && segmentResize.length != columnCount) {
      if (Math.random() > 0.5) {
        segmentResize = segmentResize.concat([columnCount]);
      } else {
        segmentResize = [columnCount].concat(segmentResize);
      }
    }
    
    if (Math.random() > 0.5) {
      resizeType = segmentResize.concat(resizeType);
    } else {
      resizeType = resizeType.concat(segmentResize);
    }
  }
  
  $("img", imageSection).each(function(index) {
    var verticalOffset = parseInt($(this).parent().css('border-top-width'),10) + parseInt($(this).parent().css('border-bottom-width'),10);
    var horizontalOffset = parseInt($(this).parent().css('border-left-width'), 10) + parseInt($(this).parent().css('border-right-width'),10);
    
    $(this).parent().css({'width': resizeType[index] * columnWidth - horizontalOffset+'px','height':columnHeight - verticalOffset+'px'});
    
    if (resizeType[index] === columnCount) {
      $(this).parent().css({'height':2*columnHeight - verticalOffset+'px'});
    }
    
    var holderRatio = $(this).parent().outerWidth()/$(this).parent().outerHeight(); // If > 1, wider than tall
    
    var imgRatio = $(this).width()/$(this).height(); // If > 1, wider than tall
    
    var relRatio = imgRatio / holderRatio;
    
    if (relRatio >= 1) {
      var height = resizeType[index] * columnHeight - horizontalOffset;
      $(this).css({'height':height+'px'});
      $(this).css({'width':$(this).width() * imgRatio + 'px'});
    } else {
      var width = resizeType[index] * columnWidth - verticalOffset;
      $(this).css({'width': width+'px'});
    }
    
    var offset = $(this).height() - $(this).parent().outerHeight();
    if (offset > 0) {
      $(this).css({'margin-top': -1 * offset/2 + 'px'});
    } else {
      $(this).css({'height':$(this).parent().outerHeight() + 'px'});
    }
    
    var horizontalOffset = $(this).width() - $(this).parent().outerWidth();
    if (horizontalOffset > 0) {
      $(this).css({'margin-left': -1 * horizontalOffset/2 + 'px'});
    }
    
  });
}