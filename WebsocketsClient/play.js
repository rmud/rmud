"use strict";

var WebSocket = WebSocket || MozWebSocket;

var userInput = document.getElementById("userInput");
var maskedInput = document.getElementById("maskedInput");
var contentWindow = document.getElementById("gameText").contentWindow
var gameTextHead = contentWindow.document.head;
var gameTextBody = contentWindow.document.body;
var connection = null;
var connected = false;

// Debug
userInput.value = "my@email.com\n" +
    "11111\n" +
    "1\n" +
    "1\n" +
    "1"

var cssFiles = ['reset.css', 'gameText.css'];

cssFiles.forEach(function(file) {
    var cssLink = contentWindow.document.createElement("link");
    cssLink.href = file; 
    cssLink.rel = "stylesheet"; 
    cssLink.type = "text/css"; 
    gameTextHead.appendChild(cssLink);
});

var gameTextParagraph = contentWindow.document.createElement('p');
gameTextBody.appendChild(gameTextParagraph);

var ansiFilter = new Filter();

function connect() {
    var serverUrl = "ws://localhost:4040";
    //var serverUrl = "ws://rmud.org:4040";
    
    if (connection) {
        connection.close();
    }
    connected = false;
    connection = new WebSocket(serverUrl);

    connection.onopen = function(event) {
        connected = true;
        console.log("connection.onopen()");
        document.getElementById("send").disabled = false;
        userInput.focus();
        gameTextParagraph.innerHTML = "";
    };

    connection.onclose = function(event) {
        if (!connected) {
            gameTextParagraph.innerHTML += "<br />Не удается установить соединение с сервером.";
            return;
        }

        var reason = "";
        switch (event.code) {
            case 1000: // Normal Closure
                reason = "Соединение закрыто.";
                break;
            case 1001: // Going Away
                reason = "Соединение закрыто удаленной стороной.";
                break;
            case 1002: // Protocol Error
                reason = "Соединение закрыто: ошибка протокола.";
                break;
            case 1003: // Unsupported Data
                reason = "Соединение закрыто: неподдерживаемый тип данных.";
                break;
            case 1005: // No Status Recvd
                reason = "Соединение закрыто: отсутствует статус.";
                break;
            case 1006: // Abnormal Closure. Bowsers normally return only this code so don't elaborate:
                reason = "Соединение закрыто.";
                break;
            case 1007: // Invalid frame payload data
                reason = "Соединение закрыто: некорректные данные.";
                break;
            case 1008: // Policy violation
                reason = "Соединение закрыто: нарушение правил.";
                break;
            case 1009: // Message too big
                reason = "Соединение закрыто: данные слишком большие.";
                break;
            case 1010: // Missing Extension
                reason = "Соединение закрыто: сервер не поддерживает требуемые расширения.";
                break;
            case 1011: // Internal Error
                reason = "Соединение закрыто: внутренняя ошибка сервера.";
                break;
            case 1012: // Service Restart
                reason = "Соединение закрыто: сервер перезагружается.";
                break;
            case 1013: // Try Again Later
                reason = "Соединение закрыто: сервер перегружен, попробуйте позже.";
                break;
            case 1014: // Bad Gateway
                reason = "Соединение закрыто: ошибка связи с основным сервером.";
                break;
            case 1015: // TLS Handshake
                reason = "Соединение закрыто: ошибка верификации сертификата.";
                break;
            default:
                reason = "Соединение закрыто: неизвестная ошибка.";
                break;
        }
        gameTextParagraph.innerHTML += "<br />" + reason;
    };

    connection.onmessage = function(event) {
        var message = JSON.parse(event.data);
        //console.log("connection.onmessage(): " + JSON.stringify(message));

        // allow 1px inaccuracy by adding 1
        var wasScrolledToBottom = isScrolledToBottom();
        //console.log((gameTextBody.scrollHeight - gameTextBody.clientHeight) + " <= " +
        //  (gameTextBody.scrollTop + 1) + "; isScrolledToBottom=" + isScrolledToBottom);

        switch (message.type) {
        case 'ansiText':
            gameTextParagraph.innerHTML += removeBell(ansiFilter.toHtml(escapeHTML(message.text)));
            break;

        case 'streamCommand':
            switch (message.command) {
            case 'echoOff':
                var hadFocus = document.activeElement == userInput;
                maskedInput.style.display = 'block';
                userInput.style.display = 'none';
                // maskedInput is single line, so get rid of newlines:
                maskedInput.value = userInput.value.replace(/\r?\n|\r/g, ' ');
                userInput.value = '';
                if (hadFocus)
                    maskedInput.focus();
                break;
            case 'echoOn':
                var hadFocus = document.activeElement == maskedInput;
                userInput.style.display = 'block';
                maskedInput.style.display = 'none';
                userInput.value = maskedInput.value;
                maskedInput.value = '';
                adjustInputHeight();
                if (hadFocus)
                    userInput.focus();
                break;
            default:
                console.error("Unknown command: " + message.command);
                break;
            }
            break;

        default:
            console.error("Unknown message type. Message: " + JSON.stringify(message));
            break;
        }

        //console.log("scrollTop=" + gameTextBody.scrollTop + ", scrollHeight=" + gameTextBody.scrollHeight +
        //  ", clientHeight=" + gameTextBody.clientHeight);
        if (wasScrolledToBottom)
          scrollToBottom();
    };

    connection.onerror = function(event) {
        //gameTextParagraph.innerHTML += "<br />WebSocket error."
    };
}

function isScrolledToBottom() {
    return gameTextBody.scrollHeight - gameTextBody.clientHeight <= gameTextBody.scrollTop + 1;
}

function scrollToBottom() {
    gameTextBody.scrollTop = gameTextBody.scrollHeight - gameTextBody.clientHeight;
}

function sendUserInput() {
    var command = (userInput.style.display != 'none') ? userInput.value : maskedInput.value;
    sendCommand(command);
    userInput.value = "";
    maskedInput.value = "";
	adjustInputHeight();
}

function sendCommand(command) {
    var message = {
        type: "command",
        text: command
    };
    connection.send(JSON.stringify(message));

    scrollToBottom();
}

window.addEventListener("keydown", function (event) {
    if (event.defaultPrevented) {
        return; // Should do nothing if the default action has been cancelled
    }

    var handled = false;
    /* if (event.key !== undefined) {
        // Handle the event with KeyboardEvent.key and set handled true.
    } else if (event.keyIdentifier !== undefined) {
        // Handle the event with KeyboardEvent.keyIdentifier and set handled true.
    } else*/
    if (event.keyCode !== undefined) {
        console.log("char=" + event.char + ", key=" + event.key + ", code=" + event.code + ", charCode=" + event.charCode +
            ", keyCode=" + event.keyCode + ", which=" + event.which + ", location=" + event.location);
        // Handle the event with KeyboardEvent.keyCode and set handled true.
        switch (event.keyCode) {
        case 13: // return
        case 14: // enter
            if (!event.shiftKey) {
                if (!document.getElementById("send").disabled) {
                    if (!event.repeat) {
                        sendUserInput();
                    }
                }
                handled = true;
            }
            break;

        case 105: // numpad page up in Safari and Firefox. Chrome returns keycode 57 + code 'Numpad9' instead.
            if (!event.repeat) {
                sendCommand("подняться");
            }
            handled = true;
            break;
        case 57: // '9'
            if (event.code == 'Numpad9') {
				if (!event.repeat) {
					sendCommand("подняться");
				}
				handled = true;
            }
            break;
        case 33: // page up
			if (event.ctrlKey || event.metaKey) {
				if (!event.repeat) {
					sendCommand("подняться");
				}
				handled = true;
			}
            break;

        case 99: // numpad page down in Safari and Firefox. Chrome returns keycode 51 + code 'Numpad3' instead.
            if (!event.repeat) {
                sendCommand("опуститься");
            }
            handled = true;
            break;
        case 51: // '3'
            if (event.code == 'Numpad3') {
				if (!event.repeat) {
					sendCommand("опуститься");
				}
				handled = true;
            }
            break;
        case 34: // page down
			if (event.ctrlKey || event.metaKey) {
				if (!event.repeat) {
					sendCommand("опуститься");
				}
				handled = true;
			}
            break;

        case 100: // numpad left arrow in Safari and Firefox. Chrome returns keyCode 52 + code 'Numpad4' instead.
			if (!event.repeat) {
				sendCommand("запад");
			}
			handled = true;
            break;
        case 52: // '4'
            if (event.code == 'Numpad4') {
				if (!event.repeat) {
					sendCommand("запад");
				}
				handled = true;
            }
            break;
        case 37: // left arrow
			if (event.ctrlKey || event.metaKey) {
				if (!event.repeat) {
					sendCommand("запад");
				}
				handled = true;
			}
            break;

        case 104: // numpad up arrow in Safari and Firefox. Chrome returns keycode 56 + code 'Numpad8' instead.
            if (!event.repeat) {
                sendCommand("север");
            }
            handled = true;
            break;
        case 56: // '8'
            if (event.code == 'Numpad8') {
				if (!event.repeat) {
					sendCommand("север");
				}
				handled = true;
            }
            break;
        case 38: // up arrow
			if (event.ctrlKey || event.metaKey) {
				if (!event.repeat) {
					sendCommand("север");
				}
				handled = true;
			}
            break;

        case 102: // numpad right arrow in Safari and Firefox. Chrome returns keycode 54 + code 'Numpad6' instead.
            if (!event.repeat) {
                sendCommand("восток");
            }
            handled = true;
            break;
        case 54: // '6'
            if (event.code == 'Numpad6') {
				if (!event.repeat) {
					sendCommand("восток");
				}
				handled = true;
            }
            break;
        case 39: // right arrow
			if (event.ctrlKey || event.metaKey) {
				if (!event.repeat) {
					sendCommand("восток");
				}
				handled = true;
			}
            break;

        case 98: // numpad down arrow in Safari and Firefox. Chrome returns keycode 50 + code 'Numpad2' instead.
            if (!event.repeat) {
                sendCommand("юг");
            }
            handled = true;
            break;
        case 50: // '2'
            if (event.code == 'Numpad2') {
				if (!event.repeat) {
					sendCommand("юг");
				}
				handled = true;
            }
            break;
        case 40: // down arrow
			if (event.ctrlKey || event.metaKey) {
				if (!event.repeat) {
					sendCommand("юг");
				}
				handled = true;
			}
            break;
        }
    }

    if (handled) {
        // Suppress "double action" if event handled
        event.preventDefault();
    }
}, true);


function escapeHTML(unsafe) {
    return unsafe
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#x27;')
        .replace(/\//g, '&#x2F;');
}

function removeBell(text) {
    return text.replace(/\u0007/g, "<span class='blink'>❗</span>");
}

// Autoexpanding user input
var userInputSetUp = false;
function adjustInputHeight() {
	var wasScrolledToBottom = isScrolledToBottom();
	userInput.rows = 1;
    if (!userInput.baseScrollHeight) {
        calculateBaseScrollHeight();
    }
	var rows = 1 + Math.ceil((userInput.scrollHeight - userInput.baseScrollHeight) / userInput.scrollHeightStep);
    //console.log("adjustInputHeight: baseScrollHeight=" + userInput.baseScrollHeight + ", scrollHeightStep=" + userInput.scrollHeightStep);
    //console.log("1+(" + userInput.scrollHeight + "-" + userInput.baseScrollHeight + ")/" + userInput.scrollHeightStep + "=" + (1 + (userInput.scrollHeight - userInput.baseScrollHeight) / userInput.scrollHeightStep) + "; rows=" + rows);
	userInput.rows = rows;
	if (wasScrolledToBottom)
		scrollToBottom();
}
function calculateBaseScrollHeight() {
    var savedValue = userInput.value;
    userInput.value = '';
    userInput.baseScrollHeight = userInput.scrollHeight;
    userInput.value = '\n'
    var step1 = userInput.scrollHeight - userInput.baseScrollHeight;
    userInput.value = '\n\n'
    var step2 = userInput.scrollHeight - userInput.baseScrollHeight - step1;
    userInput.value = '\n\n\n'
    var step3 = userInput.scrollHeight - userInput.baseScrollHeight - step2 - step1;
    // Step1 is too small, ignore it. Step2 and step3 give adequate average
    var averageStep = (step2 + step3) / 2.0;
    //console.log("step1=" + step1 + ", step2=" + step2 + ", step3=" + step3 + ", average[2 & 3]=" + averageStep);
    userInput.scrollHeightStep = averageStep;
    userInput.value = savedValue;
}
userInput.addEventListener("input", function (event) {
	adjustInputHeight();
});
adjustInputHeight();
userInput.focus();
// Put cursor at the end of userInput initially. Cross-platform solution:
setTimeout(function(){ userInput.selectionStart = userInput.selectionEnd = 10000; }, 0);


