'use strict';

const Elicom = function() {
    /** {HTMLDivElement} where to send concordance */
    conc: null;
    /** {HTMLFormElement} form with params to send for queries like conc */
    form: null;
    /** Sigma instance for this form */
    mysig: null;
    /** {HTMLDivElement} where to send concordance */
    table: null;

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
     * Append a record to conc
     * @param {*} e 
     */
    function concAppend(html) {
        if (html == EOF) {
            conc.loading = false;
            return;
        }
        conc.insertAdjacentHTML('beforeend', html);
    }

    function tableAppend(html) {
        if (html == EOF) {
            table.loading = false;
            return;
        }
        table.insertAdjacentHTML('beforeend', html);
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
     * Send query to populate concordance
     * @param {boolean} append 
     */
    function concUp(append = false) {
        if (!conc) return;
        if (!append) {
            conc.innerText = '';
        }
        let url = conc.dataset.url + "?" + pars();
        loadLines(url, concAppend, '&#10;');
    }

    function tableUp() {
        if (!table) return;
        if (table.loading) return;
        table.loading = true;
        table.innerText = '';
        let url = table.dataset.url + "?" + pars();
        loadLines(url, tableAppend, '&#10;');
    }

    /**
     * Get form values as url pars
     */
    function pars() {
        const formData = new FormData(Elicom.form);
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
        concUp();
        graphUp();
        tableUp();
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
        Elicom.update(true);
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
    function init(form) {
        if (!form) {
            console.log('[Elicom] No <form name="elicom"> found to pass params');
            return;
        }
        Elicom.form = form;
        Elicom.form.addEventListener('submit', (e) => {
            update(true);
            e.preventDefault();
        });
    }

    /**
     * Initialize the destination for concordance
     * @param {HTMLDivElement} div 
     */
    function concInit(div) {
        if (!div) { // no pb, it’s another kind of page
            return;
        }
        if (!div.dataset.url) {
            console.log('[Elicom] @data-url required <div data-url="data/conc">');
        }
        Elicom.conc = div;
    }

    /**
     *
     */
    function tableInit(div) {
        if (!div) { // no pb, it’s another kind of page
            return;
        }
        if (!div.dataset.url) {
            console.log('[Elicom] table, @data-url required for data source <div data-url="???">');
        }
        Elicom.table = div;
    }



    /**
     *
     */
    function graphInit(div) {
        if (!div) return;
        Elicom.mysig = Sigmot.sigma(div); // name of graph
    }

    /**
     * 
     * @param {*} input 
     * @returns 
     */
    function graphUp() {
        // populate a graph of words
        if (!Elicom.mysig) return;
        const formData = new FormData(Elicom.form);
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
            Elicom.mysig.graph.clear();
            Elicom.mysig.graph.read(json.data);
            Elicom.mysig.startForce();
            Elicom.mysig.refresh();
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
        concInit: concInit,
        concUp: concUp,
        graphInit: graphInit,
        graphUp: graphUp,
        init: init,
        inputDel: inputDel,
        tableInit: tableInit,
        tableUp: tableUp,
        update: update,
        urlUp: urlUp,
        suggestInit: suggestInit,
    }
}();

// update specific to this interface
(function() {
    // bottom script
    const form = document.forms['elicom'];
    Elicom.init(form); // form is required
    Elicom.concInit(document.getElementById('conc'));
    Elicom.graphInit(document.getElementById('graph'));
    Elicom.tableInit(document.getElementById('table'));
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