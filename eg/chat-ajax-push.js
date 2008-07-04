
// Using the magic of jquery, this is really easy. See jquery.com for details!

// This is the long-pull (aka "Comet"). We start this request, and then if it
// times out we start again. The server holds the connection open until there
// is an update in the message queue.
function poll_server() {
  $('#log').load(
    '/pushstream/',            // URL to load
    function(){poll_server();} // What to do upon success (recurse!)
  );
}

// We also send messages using AJAX
function send_message() {
  var username = $('#username').val();
  var message = $('#message').val();
  $('#status').load('/sendmessage/', {
    username: username,
    message:  message
  },function(){
    $('#message').val('');
    $('#message').focus();
  });
  return false;
}

// This stuff gets executed once the document is loaded
$(function(){
  // Start up the long-pull cycle
  poll_server();
  // Unobtrusively make submitting a message use send_message()
  $('#f').submit(send_message);
});

