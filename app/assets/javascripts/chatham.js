// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
$.ajaxSetup({
  statusCode: {
    401: function() {
      location.href = "/users/sign_in";
    }
  }
});

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