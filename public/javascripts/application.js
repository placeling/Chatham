// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
$.ajaxSetup({
  statusCode: {
    401: function() {
      location.href = "/users/sign_in";
    }
  }
});
