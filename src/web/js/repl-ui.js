({
  requires: [
    { "import-type": "dependency",
      protocol: "js-file",
      args: ["./check-ui"]
    },
    { "import-type": "dependency",
      protocol: "js-file",
      args: ["./output-ui"]
    },
    { "import-type": "dependency",
      protocol: "js-file",
      args: ["./error-ui"]
    },
    { "import-type": "dependency",
      protocol: "js-file",
      args: ["./text-handlers"]
    },
    { "import-type": "builtin",
      name: "world-lib"
    },
    { "import-type": "builtin",
      name: "load-lib"
    }
  ],
  nativeRequires: [
    "pyret-base/js/runtime-util"
  ],
  provides: {},
  theModule: function(runtime, _, uri,
                      checkUI, outputUI, errorUI,
                      textHandlers, worldLib, loadLib,
                      util) {
    var ffi = runtime.ffi;

    var output = jQuery("<div id='output' class='cm-s-default'>");
    output.append($("<p class='predicate_info'>Playground will check your examples against a suite of instructor-written predicates that look for interesting cases.<p>"));
    
    var outputPending = jQuery("<span>").text("Gathering results...");
    var outputPendingHidden = true;
    var canShowRunningIndicator = false;
    var running = false;

    // graph widget for playground results
    // (taken from Examplar)
    class Graph {
      constructor(value) {
        let xmlns = "http://www.w3.org/2000/svg";
        let svg = document.createElementNS(xmlns, "svg");

        svg.setAttributeNS(null, "viewBox", "0 0 36 36");
        svg.classList.add("circular-chart");
        svg.classList.add("blue");

        let circle = "M18 2.0845 "
                   + "a 15.9155 15.9155 0 0 1 0 31.831 "
                   + "a 15.9155 15.9155 0 0 1 0 -31.831";

        let bg = document.createElementNS(xmlns, "path");
        bg.classList.add("circle-bg");
        bg.setAttributeNS(null, 'd', circle);

        let fg = document.createElementNS(xmlns, "path");
        fg.classList.add("circle");
        fg.setAttributeNS(null, 'd', circle);
        fg.setAttributeNS(null, 'stroke-dasharray', "0, 100");

        let text = document.createElementNS(xmlns, "text");
        text.classList.add("percentage");
        text.setAttributeNS(null, 'x', "18");
        text.setAttributeNS(null, 'y', "20.35");

        this.bg = svg.appendChild(bg);
        this.fg = svg.appendChild(fg);
        this.text = svg.appendChild(text);
        this.element = svg;

        let fallback = {numerator: "none", denominator: "none"};
        this.numerator = (value || fallback).numerator;
        this.denominator = (value || fallback).denominator;
        this.value = {numerator: this.numerator, denominator: this.denominator};
      }

      set value(value){
        if (typeof value.numerator === "number" &&
            typeof value.denominator === "number")
        {
          this.numerator = value.numerator;
          this.denominator = value.denominator;
          this.fg.setAttributeNS(null, 'stroke-dasharray',
            `${(value.numerator / value.denominator) * 100}, 100`);
          this.text.innerHTML = `${value.numerator}⁄${value.denominator}`;
        } else {
          this.fg.setAttributeNS(null, 'stroke-dasharray', "0, 100");
          this.text.innerHTML = "?";
        }
      }
    }

    class StatusWidget {
      constructor() {
        let element = document.createElement('div');
        element.classList.add("playground_status_widget");

        let predicate_side = document.createElement('div');
        predicate_side.classList.add("playground_status");
        predicate_side.innerHTML = "Predicates<br>Satisfied";
        let predicateGraph = new Graph();
        predicate_side.prepend(predicateGraph.element);

        this.predicate_side = element.appendChild(predicate_side);
        this.element = element;

        this.predicateGraph = predicateGraph;
      }
    }

    var statusWidget = new StatusWidget();

    var RUNNING_SPINWHEEL_DELAY_MS = 1000;

    // Student data instances from definitions pane
    let studentInstances = [];

    // Number of predicates satistifed on last run
    var lastSubmissionSatisfied = 0;

    // Number of attempts with no or negative change in number of predicates satisfied
    var stagnatedAttempts = 0;

    function merge(obj, extension) {
      var newobj = {};
      Object.keys(obj).forEach(function(k) {
        newobj[k] = obj[k];
      });
      Object.keys(extension).forEach(function(k) {
        newobj[k] = extension[k];
      });
      return newobj;
    }
    var animationDivs = [];
    function closeAnimationIfOpen() {
      animationDivs.forEach(function(animationDiv) {
        animationDiv.empty();
        animationDiv.dialog("destroy");
        animationDiv.remove();
      });
      animationDivs = [];
    }
    function closeTopAnimationIfOpen() {
      var animationDiv = animationDivs.pop();
      animationDiv.empty();
      animationDiv.dialog("destroy");
      animationDiv.remove();
    }

    var interactionsCount = 0;

    function formatCode(container, src) {
      CodeMirror.runMode(src, "pyret", container);
    }

    // NOTE(joe): sadly depends on the page and hard to figure out how to make
    // this less global
    function scroll(output) {
      $(".repl").animate({
           scrollTop: output.height(),
         },
         50
      );
    }

    // This predicate rendering system is based on examplar's predicate rendering
    // (https://github.com/brownplt/examplar)
    /**
     * Generates results pane.
     * @param {Object} defined Instructor-defined values from assignment file
     * @param {PObject[]} instances Student-written data instances
     */
    function renderPredicateResults(defined, instances) {
      // Grab predicates from instructor file
      let predicates = Object.values(defined).filter(
        val => val.__proto__.$name === "pred");
      let undefinedComponents = (predicates.length === 0) ? ["predicates"] : [];
        
      // Grab type checker, general hint, and hint eligibility checkers
      let typeChecker = defined["type-checker"];
      if (!typeChecker) undefinedComponents.push("data instance type checker");
      let generalHint = defined["general-hint"];
      if (!generalHint) undefinedComponents.push("general hint");
      let isGeneralHintEligible = defined["is-general-hint-eligible"];
      if (!isGeneralHintEligible) undefinedComponents.push("general hint eligibility checker");
      let isSpecificHintEligible = defined["is-specific-hint-eligible"];
      if (!isSpecificHintEligible) undefinedComponents.push("specific hint eligibility checker");

      if (undefinedComponents.length > 0) {
        alert(`One or more required components are missing from the assignment file: ${undefinedComponents.join(', ')}. Please contact your instructor.`);
        return;
      }

      // Split data instances into those that do and don't pass the assignment's type checker
      // TODO: optimize using a reduce that produces two arrays
      let validInstances = instances.filter(sv => typeChecker.app(sv.val));
      let invalidPositions = instances.filter(sv => !typeChecker.app(sv.val))
                                      .map(sv => sv.pos);

      // Find the positions of data instances that satisfy each predicate
      let results = predicates.map(predicate => {
        return validInstances.filter(sv => runtime.getField(predicate, "f").app(sv.val))
                    .map(sv => sv.pos);
      });

      function posToLineNumbers(pos) {
        return {
          top_ln: pos.from.line,
          bot_ln: pos.to.line
        }
      }

      // logging
      fetch("https://us-central1-data-druid-brown.cloudfunctions.net/playground_logger", {
        method: 'PUT',
        body: JSON.stringify({
          student_email: $("#username").text(),
          assignment_id: window.assignmentID,
          submission: CPO.documents.get("definitions://").getValue(),
          invalid: JSON.stringify(invalidPositions.map(posToLineNumbers)),
          results: JSON.stringify(results.map(
            catchers => catchers.map(posToLineNumbers)
          ))
        }),
        headers: {
          'Content-Type': 'application/json'
        }
      });

      let numPredicates = predicates.length;
      let numSatisfied = results.filter(catchers => catchers.length > 0).length;

      // Increment stagnatedAttempts if numSatisfied did not increase
      if (numSatisfied <= lastSubmissionSatisfied) {
        stagnatedAttempts++;
      } else {
        stagnatedAttempts = 0;
      }
      lastSubmissionSatisfied = numSatisfied;

      if (invalidPositions.length > 0) {
        // Set widget graph to question mark
        statusWidget.predicateGraph.value = {};

        // Highlight offending instances
        invalidPositions.forEach(pos => pos.highlight('#ffac48'));

        let message = document.createElement('p');
        message.textContent = "The highlighted data examples did not fit the problem specifications. If you're unsure as to why, take another look at the assignment's data definition.";
        output.append(message);
      } else {
        // Set widget graph
        statusWidget.predicateGraph.value = {
          numerator: numSatisfied, denominator: numPredicates
        };
  
        let predicateInfo = document.createElement('div');
        predicateInfo.classList.add('predicate_info');
  
        let intro = document.createElement('p');
        // TODO: change to a more appropriate message
        // E.g., "You found X of the Y interesting cases."
        intro.textContent = `You satisfied ${numSatisfied} out of ${numPredicates} predicates:`;
        predicateInfo.appendChild(intro);
  
        let predicateListContainer = document.createElement('div');
        predicateListContainer.id = 'predicate_list_container';
        let predicateList = document.createElement('ul');
        predicateList.classList.add('predicate_list');
        let hintBox = document.createElement('p');
        hintBox.id = 'hint_box';
        hintBox.style.display = 'none';
        predicateListContainer.append(predicateList, hintBox);
  
        // Check if student is eligible for predicate-specific hint
        let specificHintEligible =
          isSpecificHintEligible.app(stagnatedAttempts, numPredicates, numSatisfied);
  
        /**
         * Create a circle icon for the given predicate.
         * @param {*} catchers List of srcloc each representing the satisfying student example 
         * @param {string} hint Predicate-specific hint 
         */
        function renderPredicate(catchers, hint) {
  
          let predicate = document.createElement('a');
          predicate.setAttribute('href', '#');
          predicate.classList.add('predicate');
          predicate.textContent = '💡';
  
          // Add hint if predicate is unsatisfied AND student is eligible for the hint
          if (catchers.length > 0) {
            predicate.classList.add('satisfied');
          } else if (specificHintEligible) {
            predicate.addEventListener('click', e => {
              // Remove hinted class from other predicates
              predicateList.querySelectorAll('.hintable').forEach(pred => {
                if (pred !== predicate) pred.classList.remove('hinted');
              });

              // Display/hide hint
              if (predicate.classList.toggle('hinted')) {
                // Class was added, display hint
                hintBox.textContent = "Hint: " + hint;
                hintBox.style.display = 'block';
              } else {
                // Class was removed, hide hint
                hintBox.style.display = 'none';
                hintBox.textContent = "";
              }
            });
            predicate.classList.add('hintable');
            predicate.title = "Click for a hint!";
          }
  
          predicate.addEventListener('click', e => {
            e.preventDefault();
          });
  
          // Highlight on hover, remove highlight on focus loss
          predicate.addEventListener('mouseenter', function () {
            catchers.forEach(loc => loc.highlight('#91ccec'));
          });
          predicate.addEventListener('mouseleave', function () {
            catchers.forEach(loc => loc.highlight(''));
          });
  
          return predicate;
        }
  
        // Generate predicate circle icons
        let hints = predicates.map(pred => runtime.getField(pred, "hint"));
        results.map((catchers, i) => renderPredicate(catchers, hints[i]))
          .forEach(function (predicate_widget) {
            let li = document.createElement('li');
            li.appendChild(predicate_widget);
            predicateList.appendChild(li);
          });
  
        predicateInfo.appendChild(predicateListContainer);
  
        let outro = document.createElement('p');
        // TODO: change to something more appropriate
        outro.textContent = "The predicates you satisfied are highlighted above in blue. Mouseover a predicate to see which of your examples satisfied it.";
        predicateInfo.appendChild(outro);
        
        // If student is eligible for a specific hint, display a hint tip
        if (specificHintEligible) {
          let hintNotice = document.createElement("p");
          hintNotice.textContent = "If you're feeling stuck, you can click on an unsatisfied predicate for a hint!";
          predicateInfo.appendChild(hintNotice);
        }
  
        output.append(predicateInfo);
  
        // Append general hint button if student is eligible for it AND is not for a general hint
        if (!specificHintEligible &&
            isGeneralHintEligible.app(stagnatedAttempts, numPredicates, numSatisfied)) {
          // Create div containing generalHintButton
          let generalHintDiv = document.createElement('div');
          generalHintDiv.id = "general_hint_container";
  
          let generalHintText = document.createElement('p');
          generalHintText.id = "general_hint_text"; 
          generalHintText.style.display = "none";
          generalHintText.textContent = generalHint;
  
          let generalHintButton = document.createElement('button');
          generalHintButton.id = "general_hint_button";
          generalHintButton.innerHTML = "Show Hint";
          generalHintButton.addEventListener("click", e => {
            if (generalHintText.style.display === "none") {
              // view hint
              generalHintButton.innerText = "Hide Hint";
              generalHintText.style.display = "block";
            } else {
              // hide hint
              generalHintButton.innerText = "Show Hint";
              generalHintText.style.display = "none";
            }
          });
  
          generalHintDiv.appendChild(generalHintButton);
          predicateInfo.append(generalHintDiv, generalHintText);
        }
  
        if (numSatisfied === numPredicates) {
          let reminder = document.createElement('p');
          // TODO: change
          reminder.textContent = "Nice work! Remember, the set of predicates in Playground does not cover every interesting case, so keep writing examples!";
          predicateInfo.appendChild(reminder);
        }
      }
    }

    // the result of applying `displayResult` is a function that MUST
    // NOT BE CALLED ON THE PYRET STACK.
    function displayResult(output, callingRuntime, resultRuntime, isMain) {
      var runtime = callingRuntime;
      var rr = resultRuntime;

      // MUST BE CALLED ON THE PYRET STACK
      function renderAndDisplayError(runtime, error, stack, click, result) {
        var error_to_html = errorUI.error_to_html;
        // `renderAndDisplayError` must be called on the pyret stack
        // because of this call to `pauseStack`
        return runtime.pauseStack(function (restarter) {
          // error_to_html must not be called on the pyret stack
          return error_to_html(runtime, CPO.documents, error, stack, result).
            then(function (html) {
              html.on('click', function(){
                $(".highlights-active").removeClass("highlights-active");
                html.trigger('toggleHighlight');
                html.addClass("highlights-active");
              });
              html.addClass('compile-error').appendTo(output);
              if (click) html.click();
            }).done(function () {restarter.resume(runtime.nothing)});
        });
      }

      // this function must NOT be called on the pyret stack
      return function(result) {
        var doneDisplay = Q.defer();
        var didError = false;
        // Start a new pyret stack.
        // this returned function must not be called on the pyret stack
        // b/c `callingRuntime.runThunk` must not be called on the pyret stack
        callingRuntime.runThunk(function() {
          console.log("Full time including compile/load:", JSON.stringify(result.stats));
          if(callingRuntime.isFailureResult(result)) {
            didError = true;
            // Parse Errors
            // `renderAndDisplayError` must be called on the pyret stack
            // this application runs in the context of the above `callingRuntime.runThunk`
            return renderAndDisplayError(callingRuntime, result.exn.exn, undefined, true, result);
          }
          else if(callingRuntime.isSuccessResult(result)) {
            result = result.result;
            return ffi.cases(ffi.isEither, "is-Either", result, {
              left: function(compileResultErrors) {
                closeAnimationIfOpen();
                didError = true;
                // Compile Errors
                var errors = ffi.toArray(compileResultErrors).
                  reduce(function (errors, error) {
                      Array.prototype.push.apply(errors,
                        ffi.toArray(runtime.getField(error, "problems")));
                      return errors;
                    }, []);
                // `safeCall` must be called on the pyret stack
                // this application runs in the context of the above `callingRuntime.runThunk`
                return callingRuntime.safeCall(
                  function() {
                    // eachLoop must be called in the context of the pyret stack
                    // this application runs in the context of the above `callingRuntime.runThunk`
                    return callingRuntime.eachLoop(runtime.makeFunction(function(i) {
                      // `renderAndDisplayError` must be called in the context of the
                      // pyret stack.
                      return renderAndDisplayError(callingRuntime, errors[i], [], true, result);
                    }), 0, errors.length);
                  }, function (result) { return result; }, "renderMultipleErrors");
              },
              right: function(v) {
                // TODO(joe): This is a place to consider which runtime level
                // to use if we have separate compile/run runtimes.  I think
                // that loadLib will be instantiated with callingRuntime, and
                // I think that's correct.
                return callingRuntime.pauseStack(function(restarter) {
                  rr.runThunk(function() {
                    // Clean studentInstances & prediateGraph before running predicates
                    let instances = studentInstances;
                    studentInstances = [];
                    statusWidget.predicateGraph.value = {};
                    var runResult = rr.getField(loadLib, "internal").getModuleResultResult(v);
                    console.log("Time to run compiled program:", JSON.stringify(runResult.stats));
                    if(rr.isSuccessResult(runResult)) {
                      // On successful compilation

                      // Find values defined in import file (written by instructor for each assignment)
                      let predicateModuleName = Object.keys(rr.modules).find(key => key.endsWith(window.assignmentID));
                      let defined = rr.getField(rr.modules[predicateModuleName], "defined-values");

                      return rr.safeCall(function() {
                        return renderPredicateResults(defined, instances);
                      }, function(_) {
                        outputPending.remove();
                        outputPendingHidden = true;
                        return true;
                      }, "rr.drawCheckResults");
                    } else {
                      didError = true;
                      // `renderAndDisplayError` must be called in the context of the pyret stack.
                      // this application runs in the context of the above `rr.runThunk`.
                      return renderAndDisplayError(resultRuntime, runResult.exn.exn,
                                                   runResult.exn.pyretStack, true, runResult);
                    }
                  }, function(runResult) {
                    if (rr.isFailureResult(runResult)) {
                      rr.runThunk(function() {
                        return renderAndDisplayError(resultRuntime, runResult.exn.exn,
                                                     runResult.exn.pyretStack, true, runResult, "compile-error");
                      }, function(_) {
                        restarter.resume(callingRuntime.nothing);
                      });
                    } else {
                      restarter.resume(callingRuntime.nothing);
                    }
                  });
                });
              }
            });
          }
          else {
            doneDisplay.reject("Error displaying output");
            console.error("Bad result: ", result);
            didError = true;
            // `renderAndDisplayError` must be called in the context of the pyret stack.
            // this application runs in the context of `callingRuntime.runThunk`
            return renderAndDisplayError(
              callingRuntime,
              ffi.InternalError("Got something other than a Pyret result when running the program.",
                                ffi.makeList(result)));
          }
        }, function(_) {
          if (didError) {
            var snippets = output.find(".CodeMirror");
            for (var i = 0; i < snippets.length; i++) {
              snippets[i].CodeMirror.refresh();
            }
          }
          doneDisplay.resolve("Done displaying output");
          return callingRuntime.nothing;
        });
      return doneDisplay.promise;
      }
    }

    //: -> (code -> printing it on the repl)
    function makeRepl(container, repl, runtime, options) {

      var Jsworld = worldLib;
      var items = [];
      var pointer = -1;
      var current = "";
      function loadItem() {
        CM.setValue(items[pointer]);
        }
        function saveItem() {
          items.unshift(CM.getValue());
      }
      function prevItem() {
        if (pointer === -1) {
          current = CM.getValue();
        }
        if (pointer < items.length - 1) {
          pointer++;
          loadItem();
          CM.refresh();
          }
        }
      function nextItem() {
        if (pointer >= 1) {
          pointer--;
          loadItem();
          CM.refresh();
        } else if (pointer === 0) {
          CM.setValue(current);
          CM.refresh();
          pointer--;
        }
      }

      container.append(mkWarningUpper());
      container.append(mkWarningLower());

      var promptContainer = jQuery("<div class='prompt-container'>");
      var prompt = jQuery("<span>").addClass("repl-prompt").attr("title", "Enter Pyret code here");
      function showPrompt() {
        promptContainer.hide();
        promptContainer.fadeIn(100);
        CM.setValue("");
        CM.focus();
        CM.refresh();
      }
      promptContainer.append(prompt);

      container.on("click", function(e) {
        if($(CM.getTextArea()).parent().offset().top < e.pageY) {
          CM.focus();
        }
      });

      function maybeShowOutputPending() {
        outputPendingHidden = false;
        setTimeout(function() {
          if(!outputPendingHidden) {
            output.append(outputPending);
          }
        }, 200);
      }
      runtime.setStdout(function(str) {
        });
      var currentZIndex = 15000;
      runtime.setParam("current-animation-port", function(dom, title, closeCallback) {
          var animationDiv = $("<div>").css({"z-index": currentZIndex + 1});
          animationDivs.push(animationDiv);
          output.append(animationDiv);
          function onClose() {
            Jsworld.shutdownSingle({ cleanShutdown: true });
            closeTopAnimationIfOpen();
          }
          closeCallback(closeTopAnimationIfOpen);
          animationDiv.dialog({
            title: title,
            position: ["left", "top"],
            bgiframe : true,
            modal : true,
            overlay : { opacity: 0.5, background: 'black'},
            //buttons : { "Save" : closeDialog },
            width : "auto",
            height : "auto",
            close : onClose,
            closeOnEscape : true
          });
          animationDiv.append(dom);
          var dialogMain = animationDiv.parent();
          dialogMain.css({"z-index": currentZIndex + 1});
          dialogMain.prev().css({"z-index": currentZIndex});
          currentZIndex += 2;
        });

      runtime.setParam("d3-port", function(dom, optionMutator, onExit, buttons) {
          // duplicate the code for now
          var animationDiv = $("<div>");
          animationDivs.push(animationDiv);
          output.append(animationDiv);
          function onClose() {
            onExit();
            closeTopAnimationIfOpen();
          }
          var baseOption = {
            position: [5, 5],
            bgiframe : true,
            modal : true,
            overlay : {opacity: 0.5, background: 'black'},
            width : 'auto',
            height : 'auto',
            close : onClose,
            closeOnEscape : true,
            create: function() {

              // from http://fiddle.jshell.net/JLSrR/116/

              var titlebar = animationDiv.prev();
              buttons.forEach(function(buttonData) {
                var button = $('<button/>'),
                    left = titlebar.find( "[role='button']:last" ).css('left');
                button.button({icons: {primary: buttonData.icon}, text: false})
                       .addClass('ui-dialog-titlebar-close')
                       .css('left', (parseInt(left) + 27) + 'px')
                       .click(buttonData.click)
                       .appendTo(titlebar);
              });
            }
          }
          animationDiv.dialog(optionMutator(baseOption)).dialog("widget").draggable({
            containment: "none",
            scroll: false,
          });
          animationDiv.append(dom);
          var dialogMain = animationDiv.parent();
          dialogMain.css({"z-index": currentZIndex + 1});
          dialogMain.prev().css({"z-index": currentZIndex});
          currentZIndex += 2;
          return animationDiv;
      });
      runtime.setParam("remove-d3-port", function() {
          closeTopAnimationIfOpen();
          // don't call .dialog('close'); because that would trigger onClose and thus onExit.
          // We don't want that to happen.
      });

      runtime.setParam('chart-port', function(args) {
        const animationDiv = $(args.root);
        animationDivs.push(animationDiv);
        output.append(animationDiv);

        let timeoutTrigger = null;

        const windowOptions = {
          title: '',
          position: [5, 5],
          bgiframe: true,
          width: 'auto',
          height: 'auto',
          beforeClose: () => {
            args.draw(options => $.extend({}, options, {chartArea: null}));
            args.onExit();
            closeTopAnimationIfOpen();
          },
          create: () => {
            // from http://fiddle.jshell.net/JLSrR/116/
            const titlebar = animationDiv.prev();
            titlebar.find('.ui-dialog-title').css({'white-space': 'pre'});
            let left = parseInt(titlebar.find("[role='button']:last").css('left'));
            function addButton(icon, fn) {
              left += 27;
              const btn = $('<button/>')
                .button({icons: {primary: icon}, text: false})
                .addClass('ui-dialog-titlebar-close')
                .css('left', left + 'px')
                .click(fn)
                .appendTo(titlebar);
              return btn;
            }

            addButton('ui-icon-disk', () => {
              let savedOptions = null;
              args.draw(options => {
                savedOptions = options;
                return $.extend({}, options, {chartArea: null});
              });
              const download = document.createElement('a');
              download.href = args.getImageURI();
              download.download = 'chart.png';
              // from https://stackoverflow.com/questions/3906142/how-to-save-a-png-from-javascript-variable
              function fireEvent(obj, evt){
                const fireOnThis = obj;
                if(document.createEvent) {
                  const evObj = document.createEvent('MouseEvents');
                  evObj.initEvent(evt, true, false);
                  fireOnThis.dispatchEvent(evObj);
                } else if(document.createEventObject) {
                  const evObj = document.createEventObject();
                  fireOnThis.fireEvent('on' + evt, evObj);
                }
              }
              fireEvent(download, 'click');
              args.draw(_ => savedOptions);
            });
          },
          resize: () => {
            if (timeoutTrigger) clearTimeout(timeoutTrigger);
            timeoutTrigger = setTimeout(args.draw, 100);
          },
        };

        if (args.isInteractive) {
          $.extend(windowOptions, {
            closeOnEscape: true,
            modal: true,
            overlay: {opacity: 0.5, background: 'black'},
            title: '   Interactive Chart',
          });
        } else {
          // need hide to be true so that the dialog will fade out when
          // closing (see https://api.jqueryui.com/dialog/#option-hide)
          // this gives time for the chart to actually render
          $.extend(windowOptions, {hide: true});
        }

        animationDiv
          .dialog($.extend({}, windowOptions, args.windowOptions))
          .dialog('widget')
          .draggable({
            containment: 'none',
            scroll: false,
          });

        // explicit call to draw to correct the dimension after the dialog has been opened
        args.draw();

        const dialogMain = animationDiv.parent();
        if (args.isInteractive) {
          dialogMain.css({'z-index': currentZIndex + 1});
          dialogMain.prev().css({'z-index': currentZIndex});
          currentZIndex += 2;
        } else {
          // a trick to hide the dialog while actually rendering it
          dialogMain.css({
            top: window.innerWidth * 2,
            left: window.innerHeight * 2,
          });
          animationDiv.dialog('close');
        }
      });

      runtime.setParam('remove-chart-port', function() {
          closeTopAnimationIfOpen();
          // don't call .dialog('close'); because that would trigger onClose and thus onExit.
          // We don't want that to happen.
      });

      var breakButton = options.breakButton;
      container[0].appendChild(statusWidget.element);
      container.append(output);

      var img = $("<img>").attr({
        "src": "/img/pyret-spin.gif",
        "width": "25px",
      }).css({
        "vertical-align": "middle"
      });
      var runContents;
      function afterRun(cm) {
        return function() {
          running = false;
          outputPending.remove();
          outputPendingHidden = true;

          options.runButton.empty();
          options.runButton.append(runContents);
          options.runButton.attr("disabled", false);
          breakButton.attr("disabled", true);
          canShowRunningIndicator = false;
          if(cm) {
            cm.setValue("");
            cm.setOption("readonly", false);
          }
          //output.get(0).scrollTop = output.get(0).scrollHeight;
          showPrompt();
          setTimeout(function(){
            $("#output > .compile-error .cm-future-snippet").each(function(){this.cmrefresh();});
          }, 200);
        }
      }
      function setWhileRunning() {
        runContents = options.runButton.contents();
        canShowRunningIndicator = true;
        setTimeout(function() {
         if(canShowRunningIndicator) {
            options.runButton.attr("disabled", true);
            breakButton.attr("disabled", false);
            options.runButton.empty();
            var text = $("<span>").text("Running...");
            text.css({
              "vertical-align": "middle"
            });
            options.runButton.append([img, text]);
          }
        }, RUNNING_SPINWHEEL_DELAY_MS);
      }

      // SETUP FOR TRACING ALL OUTPUTS
      var replOutputCount = 0;
      outputUI.installRenderers(repl.runtime);

      repl.runtime.setParam("onTrace", function(loc, val, url) {
        if (repl.runtime.getParam("currentMainURL") !== url) { return { "onTrace": "didn't match" }; }
        if (repl.runtime.isNothing(val)) { return { "onTrace": "was nothing" }; }
        return repl.runtime.pauseStack(function(restarter) {
          repl.runtime.runThunk(function() {
            return repl.runtime.toReprJS(val, repl.runtime.ReprMethods["$cpo"]);
          }, function(container) {
            if (repl.runtime.isSuccessResult(container)) {
              let pos = outputUI.Position.fromSrcArray(loc, CPO.documents, {});
              studentInstances.push({val: val, pos: pos});
            } else {
              $(output).append($("<div>").addClass("error trace")
                               .append($("<span>").addClass("trace").text("Trace #" + (++replOutputCount)))
                               .append($("<span>").text("<error displaying value: details logged to console>")));
              console.log(container.exn);
              scroll(output);
            }
            restarter.resume(val);
          });
        });
      });

      var runMainCode = function(src, uiOptions) {
        if(running) { return; }
        running = true;
        output.empty();
        promptContainer.hide();
        lastEditorRun = uiOptions.cm || null;
        setWhileRunning();

        CPO.documents.forEach(function(doc, name) {
          if (name.indexOf("interactions://") === 0)
            CPO.documents.delete(name);
        });

        CPO.documents.set("definitions://", uiOptions.cm.getDoc());

        interactionsCount = 0;
        replOutputCount = 0;
        logger.log('run', { name      : "definitions://",
                            type_check: !!uiOptions["type-check"]
                          });
        var options = {
          typeCheck: !!uiOptions["type-check"],
          checkAll: false // NOTE(joe): this is a good spot to fetch something from the ui options
                          // if this becomes a check box somewhere in CPO
        };

        // TODO: logging and/or injection?
        var replResult = repl.restartInteractions(src, options);
        var startRendering = replResult.then(function(r) {
          maybeShowOutputPending();
          return r;
        });
        var doneRendering = startRendering.then(displayResult(output, runtime, repl.runtime, true)).fail(function(err) {
          console.error("Error displaying result: ", err);
        });
        doneRendering.fin(afterRun(false));
      };

      var runner = function(code) {
        if(running) { return; }
        running = true;
        items.unshift(code);
        pointer = -1;
        var echoContainer = $("<div class='echo-container'>");
        var echoSpan = $("<span>").addClass("repl-echo");
        var echo = $("<textarea>");
        echoSpan.append(echo);
        echoContainer.append(echoSpan);
        write(echoContainer);
        var echoCM = CodeMirror.fromTextArea(echo[0], { readOnly: true });
        echoCM.setValue(code);
        CM.setValue("");
        promptContainer.hide();
        setWhileRunning();
        interactionsCount++;
        var thisName = 'interactions://' + interactionsCount;
        CPO.documents.set(thisName, echoCM.getDoc());
        logger.log('run', { name: thisName });
        var replResult = repl.run(code, thisName);
//        replResult.then(afterRun(CM));
        var startRendering = replResult.then(function(r) {
          maybeShowOutputPending();
          return r;
        });
        var doneRendering = startRendering.then(displayResult(output, runtime, repl.runtime, false)).fail(function(err) {
          console.error("Error displaying result: ", err);
        });
        doneRendering.fin(afterRun(CM));
      };

      var CM = CPO.makeEditor(prompt, {
        simpleEditor: true,
        run: runner,
        initial: "",
        cmOptions: {
          extraKeys: CodeMirror.normalizeKeyMap({
            'Enter': function(cm) { runner(cm.getValue(), {cm: cm}); },
            'Shift-Enter': "newlineAndIndent",
            'Tab': 'indentAuto',
            'Up': prevItem,
            'Down': nextItem,
            'Ctrl-Up': "goLineUp",
            'Ctrl-Alt-Up': "goLineUp",
            'Ctrl-Down': "goLineDown",
            'Ctrl-Alt-Down': "goLineDown",
            'Esc Left': "goBackwardSexp",
            'Alt-Left': "goBackwardSexp",
            'Esc Right': "goForwardSexp",
            'Alt-Right': "goForwardSexp",
            'Ctrl-Left': "goBackwardToken",
            'Ctrl-Right': "goForwardToken"
          })
        }
      }).cm;

      CM.on('beforeChange', function(instance, changeObj){textHandlers.autoCorrect(instance, changeObj, CM);});

      CPO.documents.set('definitions://', CM.getDoc());

      var lastNameRun = 'interactions';
      var lastEditorRun = null;

      var write = function(dom) {
        output.append(dom);
      };

      var onBreak = function() {
        breakButton.attr("disabled", true);
        repl.stop();
        closeAnimationIfOpen();
        Jsworld.shutdown({ cleanShutdown: true });
        showPrompt();
      };

      breakButton.attr("disabled", true);
      breakButton.click(onBreak);

      return {
        runCode: runMainCode,
        focus: function() { CM.focus(); }
      };
    }

    return runtime.makeJSModuleReturn({
      makeRepl: makeRepl,
      makeEditor: CPO.makeEditor
    });

  }
})