var OPACITY_INACTIVE = 0.2;
var OPACITY_ACTIVE = 1;
var OPACITY_TOUCH = 0.6;

var wsInterval = null;
var connected = false;
var lastPreso = null;

function hideLoader() {
  $(".loader").remove();
}

function showLoader() {
  hideLoader();
  $(document.body).append('<div class="loader"><div>&nbsp;</div></div>');
}

function displayPresos(ws, data) {
  if (data.length == 0) {
    $("#presos").empty();
    $("#presos").append("No presentations");
  } else {
    var restore = null;
    $("#presos").empty();
    data.forEach(function(item) {
      $("#presos").append("<li data-path='" + item["path"] + "' data-name='" + item["name"] + "' class='app-button preso'>" + item["name"] + "</li>" );
      if ( item["r"] == true ) {
        restore = { slide: parseInt(item["slide"]+""),
                    total: parseInt(item["total"]+""),
                    path: item["path"],
                    name: item["name"],
                    ws: ws };
      }
    });

    $(".preso").click(function() {
      showLoader();
      ws.send( JSON.stringify({command: "open", path: $(this).attr("data-path"), name: $(this).attr("data-name") }) );
    });

    if ( restore != null ) {
      App.load("presentation");
      setTimeout(function() {
        lastPreso = restore;
        applicationState(lastPreso);
      }, 500);
    }

  }
};

function applicationState(state) {
  $("#file").text(state.name);
  $("#currentSlide").text(state.slide);
  $("#totalSlide").text(state.total);
  $("#stopPreso").click(function() {
    if ( confirm("Are you sure?") ) {
      showLoader();
      state.ws.send( JSON.stringify({ command: "stop", document: state.path }) );
    }
  });

  presoControlsEffectsTriggers();
  presoControlTriggers();
  presoControlsEffectsCleanup();
}

function presoControlsEffectsTriggers() {
  $(".scp").on("touchstart", function() {
    $("#btnPrevImg").css("opacity", OPACITY_TOUCH);
  });
  $(".scn").on("touchstart", function() {
    $("#btnNextImg").css("opacity", OPACITY_TOUCH);
  });
  $(".sc").on("touchend", function() {
    presoControlsEffects();
  });
}

function presoControlTriggers() {
  $("#btnPrev").click(function() {
    if ( lastPreso.slide > 1 ) {
      showLoader();
      lastPreso.ws.send( JSON.stringify({ command: "prev", current: lastPreso.slide, document: lastPreso.path }) );
    }
  });
  $("#btnNext").click(function() {
    if ( lastPreso.slide < lastPreso.total ) {
      showLoader();
      lastPreso.ws.send( JSON.stringify({ command: "next", current: lastPreso.slide, document: lastPreso.path }) );
    }
  });
}

function presoControlsEffectsCleanup() {
  $("#btnPrevImg").css("opacity", ( lastPreso.slide == 1 ) ? OPACITY_INACTIVE : OPACITY_ACTIVE );
  $("#btnNextImg").css("opacity", ( lastPreso.slide == lastPreso.total ) ? OPACITY_INACTIVE : OPACITY_ACTIVE );
}

$(document).ready(function() {

  App.load("noconnection");

  $("#instructions").click(function() {
    App.load("instructions");
  });

  setInterval(function() {
    if (!connected) {
      var ws = new WebSocket('ws://' + window.location.host + window.location.pathname);
      ws.onopen = function()  {
        hideLoader();
        connected = true;
        if ( lastPreso == null ) {
          App.load("list");
        } else {
          App.load("presentation");
          lastPreso.ws = ws;
          applicationState(lastPreso);
        }
      };
      ws.onclose   = function()  {
        connected = false;
        App.load("noconnection");
        clearInterval(wsInterval);
      }
      ws.onmessage = function(m) {
        hideLoader();
        try {
          var p = JSON.parse( m.data );
          if ( p.response == "state" ) {
            setTimeout(function() {
              displayPresos( ws, p.presos )
            }, 500);
          } else if ( p.response == "opened" ) {
            App.load("presentation");
            setTimeout(function() {
              lastPreso = { slide: 1,
                            total: p.slides,
                            path: p.path,
                            name: p.name,
                            ws: ws };
              applicationState(lastPreso);
            }, 500);
          } else if ( p.response == "quit" ) {
            lastPreso = null;
            ws.close();
          } else if ( p.response == "changed" ) {
            lastPreso.slide = parseInt(p.slide+"");
            $("#currentSlide").text( lastPreso.slide );
            presoControlsEffectsCleanup();
          } else if ( p.response == "failed" ) {
            alert("Command " + p.command + " failed with code " + p.code + ".\nReason: " + p.error);
          } else {
            alert("Unsupported server response: " + p.response);
          }
        } catch (e) {
          console.error("Error while parsing incoming WS data.", m.data);
        }
      };
    }
  }, 1000);
});