'use strict';

const Elicom = function() {
    /** {HTMLFormElement} form with params to send for queries like conc */
    var form = false;
    /** array of {HTMLDivElement} with html updates */
    var divs = {};
    /** Sigma instance for this form */
    var mysig = false;
    const EOF = '\u000A';

    function loadJson(url, callback) {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', url, true);
        xhr.responseType = 'json';
        xhr.onload = function() {
            var status = xhr.status;
            if (status === 200) {
                callback(xhr.response, null);
            } else { // in case of error ?
                callback(xhr.response, status);
            }
        };
        xhr.send();
    }

    /**
     * Get URL and send line by line to a callback function
     * @param {String} url 
     * @param {function} callback 
     * @returns 
     */
    function loadLines(url, callback, sep = '\n') {
        return new Promise(function(resolve, reject) {
            var xhr = new XMLHttpRequest();

            var start = 0;

            xhr.onprogress = function() {
                // loop on separator
                var end;
                while ((end = xhr.response.indexOf(sep, start)) >= 0) {
                    callback(xhr.response.slice(start, end));
                    start = end + sep.length;
                }
            };

            xhr.onload = function() {
                let part = xhr.response.slice(start);
                if (part.trim()) callback(part);
                // last, send a message to callback
                callback(EOF);
                resolve();
            };

            xhr.onerror = function() {
                reject(Error('Connection failed'));
            };

            xhr.responseType = 'text';
            xhr.open('GET', url);
            xhr.send();
        });
    }

    /**
     * Append a corres record to suggestions
     * @param {HTMLDivElement} suggest block where to append suggestions 
     * @param {*} line 
     */
    function corresAppend(suggest, json) {
        if (!json.trim()) { // sometimes empty
            return;
        }
        try {
            var data = JSON.parse(json);
        } catch (err) {
            console.log(Error('parsing: "' + json + "\"\n" + err));
            return;
        }
        // maybe meta
        if (!data.text || !data.id) {
            return;
        }

        let corres = document.createElement('div');
        corres.className = "corres";
        const hits = (data.hits) ? " (" + data.hits + ")" : "";
        if (data.html) {
            corres.innerHTML = data.html + hits;
        } else if (data.text) {
            corres.innerHTML = data.text + hits;
        } else { // ?? bad !
            corres.innerHTML = data.id + hits;
        }
        corres.dataset.id = data.id;
        corres.addEventListener('click', corresPush);
        corres.input = suggest.input;
        suggest.appendChild(corres);
    }

    /**
     * Start population of corres suggestion 
     * @param {Event} e 
     */
    function corresUp(e) {
        const input = e.currentTarget;
        const suggest = input.suggest;
        // get forms params
        const formData = new FormData(input.form);
        const pars = new URLSearchParams(formData);
        pars.set("glob", input.value); // add the suggest query

        // search form sender and receiver
        const url = input.dataset.url + "?" + pars;
        suggest.innerText = '';
        loadLines(url, function(json) {
            corresAppend(suggest, json);
        });
    }

    /**
     * Get form values as url pars
     */
    function pars() {
        const formData = new FormData(form);
        // delete empty values, be careful, deletion will modify iterator
        const keys = Array.from(formData.keys());
        for (const key of keys) {
            if (!formData.get(key)) formData.delete(key);
        }
        return new URLSearchParams(formData);
    }

    /**
     * Update interface with data
     */
    function update(pushState = false) {
        for (let key in divs) upDiv(key);
        graphUp();
        if (pushState) urlUp();
    }

    function urlUp() {
        const url = new URL(window.location);
        url.search = pars();
        window.history.pushState({}, '', url);
    }

    /**
     * Delete an hidden field
     * @param {Event} e 
     */
    function inputDel(e) {
        const label = e.currentTarget.parentNode;
        label.parentNode.removeChild(label);
        update(true);
    }

    /**
     * Push a value for a correspondant
     * @param {Event} e 
     */
    function corresPush(e) {
        const corres = e.currentTarget;
        const label = document.createElement("label");
        label.className = 'corres';
        const a = document.createElement("a");
        a.innerText = '🞭';
        a.className = 'inputDel';
        a.addEventListener('click', inputDel);
        label.appendChild(a);
        const input = document.createElement("input");
        input.name = corres.input.dataset.name;
        input.type = 'hidden';
        input.value = corres.dataset.id;
        label.appendChild(input);
        const text = document.createTextNode(corres.textContent.replace(/ *\(\d+\) *$/, ''));
        label.appendChild(text);
        corres.input.parentNode.insertBefore(label, corres.input);
        corres.input.focus();
        corres.input.suggest.hide();
        update(true); // update interface
    }

    /**
     * Attached to a suggest pannel, hide
     */
    function hide() {
        const suggest = this;
        suggest.blur();
        suggest.style.display = 'none';
        suggest.input.value = '';
        window.suggest = null;
    }

    /**
     * Attached to a suggest pannel, show
     */
    function show() {
        const suggest = this;
        if (window.suggest && window.suggest != suggest) {
            window.suggest.hide();
        }
        window.suggest = suggest;
        suggest.style.display = 'block';
    }

    /**
     * 
     * @param {*} form 
     * @returns 
     */
    function init(el) {
        if (!el) {
            console.log('[Elicom] No <form name="elicom"> found to pass params');
            return;
        }
        form = el;
        form.addEventListener('submit', (e) => {
            update(true);
            e.preventDefault();
        });
    }

    function words(links, conc) {
        const div = document.getElementById(links);
        if (!div) return;
        if (!form.q) return;
        div.addEventListener('click', function(event) {
            const src = event.target || event.srcElement;
            if (src.tagName.toLowerCase() != 'a') return;
            form.q.value = src.innerText;
            upDiv(conc);
        });
    }

    /**
     * Record a div to be updated by an url
     * @param {*} div 
     * @returns 
     */
    function divSetup(id) {
        const div = document.getElementById(id);
        if (!div) { // no pb, it’s another kind of page
            return;
        }
        if (!div.dataset.url) {
            console.log('[Elicom] @data-url required <div data-url="data/conc">');
        }
        divs[id] = div;
    }

    /**
     * Send query to populate concordance
     * @param {boolean} append 
     */
    function upDiv(key, append = false) {
        let div = divs[key];
        if (!div) return; // disappeared ?
        if (div.loading) return; // still loading
        div.loading = true;
        if (!append) {
            div.innerText = '';
        }
        let url = div.dataset.url + "?" + pars();
        loadLines(url, function(html) {
            insLine(div, html);
        }, '&#10;');
    }

    /**
     * Append a record to a div
     * @param {*} html 
     * @returns 
     */
    function insLine(div, html) {
        if (!div) { // what ?
            return false;
        }
        // last line, liberate div for next load
        if (html == EOF) {
            div.loading = false;
            return;
        }
        div.insertAdjacentHTML('beforeend', html);
    }

    /**
     *
     */
    function graphInit(div) {
        if (!div) return;
        mysig = Sigmot.sigma(div); // name of graph
    }

    /**
     * 
     * @param {*} input 
     * @returns 
     */
    function graphUp() {
        // populate a graph of words
        if (!mysig) return;
        const formData = new FormData(form);
        const pars = new URLSearchParams(formData);
        // if query, what should I do ?
        if (formData.get('q')) {
            var url = 'data/cooc.json' + "?" + pars;
        } else if (formData.get('senderid') || formData.get('receiverid')) {
            var url = 'data/correswords.json' + "?" + pars;
        } else {
            var url = 'data/wordnet.json' + "?" + pars;
        }
        loadJson(url, function(json) {
            if (!json) {
                console.log("[Elicom] load error url=" + url)
                return;
            }
            if (!json.data) {
                console.log("[Elicom] grap load error\n" + json)
                return;
            }
            mysig.graph.clear();
            mysig.graph.read(json.data);
            mysig.startForce();
            mysig.refresh();
        });
    }



    /**
     * Intitialize an input with suggest
     * @param {HTMLInputElement} input 
     * @returns 
     */
    function suggestInit(input) {
        if (!input) {
            console.log("[Elicom] No <input> to equip");
            return;
        }
        if (input.list) { // create a list
            console.log("[Elicom] <datalist> is bad for filtering\n" + input);
        }
        if (!input.dataset.url) {
            console.log("[Elicom] No @data-url to get data from\n" + input);
            return;
        }
        if (!input.dataset.name) {
            console.log("[Elicom] No @data-name to create params\n" + input);
            return;
        }
        input.autocomplete = 'off';
        // create suggest
        const suggest = document.createElement("div");
        suggest.className = "suggest " + input.dataset.name;
        input.parentNode.insertBefore(suggest, input.nextSibling);
        input.suggest = suggest;
        suggest.input = input;
        suggest.hide = hide;
        suggest.show = show;
        // global click hide current suggest
        window.addEventListener('click', (e) => {
            if (window.suggest) window.suggest.hide();
        });
        // click in suggest, avoid hide effect at body level
        input.parentNode.addEventListener('click', (e) => {
            e.stopPropagation();
        });
        // control suggests, 
        input.addEventListener('click', function(e) {
            if (suggest.style.display != 'block') {
                suggest.show();
            } else {
                suggest.hide();
            }
        });

        input.addEventListener('click', corresUp);
        input.addEventListener('input', corresUp);
        input.addEventListener('input', function(e) { suggest.show(); });

        suggest.addEventListener("touchstart", function(e) {
            // si on défile la liste de résultats sur du tactile, désafficher le clavier
            input.blur();
        });
        input.addEventListener('keyup', function(e) {
            e = e || window.event;
            if (e.key == 'Esc' || e.key == 'Escape') {
                suggest.hide();
            } else if (e.key == 'Backspace') {
                if (input.value) return;
                suggest.hide();
            } else if (e.key == 'ArrowDown') {
                if (input.value) return;
                suggest.show();
            } else if (e.key == 'ArrowUp') {
                // focus ?
            }
        });
    }

    return {
        graphInit: graphInit,
        graphUp: graphUp,
        words: words,
        init: init,
        inputDel: inputDel,
        divSetup: divSetup,
        update: update,
        urlUp: urlUp,
        suggestInit: suggestInit,
    }
}();

const Bislide = function() {
    function init() {
        // Initialize Sliders
        let els = document.getElementsByClassName("bislide");
        for (let x = 0; x < els.length; x++) {
            let sliders = els[x].getElementsByTagName("input");
            let slider1;
            let slider2;
            for (let y = 0; y < sliders.length; y++) {
                if (sliders[y].type !== "range") continue;
                if (!slider1) {
                    slider1 = sliders[y];
                    continue;
                }
                slider2 = sliders[y];
                break;
            }
            if (!slider2) continue;
            els[x].values = els[x].getElementsByClassName("values")[0];
            els[x].slider1 = slider1;
            els[x].slider1.oninput = Bislide.input;
            els[x].slider1.onchange = Bislide.change;
            els[x].slider2 = slider2;
            els[x].slider2.oninput = Bislide.input;
            els[x].slider2.onchange = Bislide.change;
            slider2.oninput();
        }
    }

    function change() {

        Elicom.update(true);
    }

    function input() {
        // Get slider values
        var parent = this.parentNode;
        var val1 = parseFloat(parent.slider1.value);
        var val2 = parseFloat(parent.slider2.value);
        // swap value if needed 
        if (val1 > val2) {
            parent.slider1.value = val2;
            parent.slider2.value = val1;
        }
        // display
        if (!parent.values) return;
        parent.values.innerHTML = parent.slider1.value + " – " + parent.slider2.value;
    }
    return {
        init: init,
        input: input,
        change: change,
    }
}();


// update specific to this interface
(function() {
    // bottom script
    Bislide.init();
    const form = document.forms['elicom'];
    if (!form) return;
    Elicom.init(form); // form is required
    Elicom.divSetup('relwords');
    Elicom.divSetup('conc');
    Elicom.words('relwords', 'conc');
    // Elicom.pushdiv(document.getElementById('table'));
    // Elicom.graphInit(document.getElementById('graph'));
    const inputs = document.querySelectorAll("input.multiple[data-url]");
    for (let i = 0; i < inputs.length; i++) {
        Elicom.suggestInit(inputs[i]);
    }
    // corres fields to animate
    for (var item of document.querySelectorAll("a.inputDel")) {
        item.addEventListener('click', Elicom.inputDel);
    }
    if (form.hstop) {
        form.hstop.addEventListener('change', Elicom.tableUp);
        form.hstop.addEventListener('change', Elicom.urlUp);
    }
    if (form.cat) {
        form.cat.addEventListener('change', Elicom.tableUp);
        form.cat.addEventListener('change', Elicom.urlUp);
    }
    if (form.distrib) {
        form.distrib.addEventListener('change', Elicom.tableUp);
        form.distrib.addEventListener('change', Elicom.urlUp);
    }
    Elicom.update();
})();