'use strict';

const Elicom = function() {
    self: this;
    /** {HTMLDivElement} where to send concordance */
    conc: null;
    /** {HTMLFormElement} form with params to send for queries like conc */
    form: null;

    /**
     * Get URL and send line by line to a callback function
     * @param {*} url 
     * @param {*} callback 
     * @returns 
     */
    function loadlines(url, callback, sep = '\n') {
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
     * 
     * @param {*} e 
     */
    function concRes(result) {
        conc.insertAdjacentHTML('beforeend', result);
    }

    /**
     * 
     * @param {HTMLDivElement} suggest block where to append suggestions 
     * @param {*} line 
     */
    function corres(suggest, json) {
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
        // for HTML
        // div.insertAdjacentHTML('beforeend', line);
    }

    function corresFetch(e) {
        const input = e.currentTarget;
        const suggest = input.suggest;
        // get forms params
        const formData = new FormData(input.form);
        const pars = new URLSearchParams(formData);
        pars.set("glob", input.value); // add the suggest query

        // search form sender and receiver
        const url = input.dataset.url + "?" + pars;
        suggest.innerText = '';
        loadlines(url, function(json) {
            corres(suggest, json);
        });
    }

    /**
     * Send query to populate concordance
     * @param {boolean} append 
     */
    function concFetch(append = false) {
        if (!append) {
            conc.innerText = '';
        }
        const formData = new FormData(form);
        const pars = new URLSearchParams(formData);
        const url = conc.dataset.url + "?" + pars;
        loadlines(url, concRes, '&#10;');
    }

    /**
     * Push a value for a correspondant
     * @param {*} e 
     */
    function corresPush(e) {
        const corres = e.currentTarget;
        const label = document.createElement("label");
        const html = '<a onclick="let p=this.parentNode; p.parentNode.removeChild(p); Elicom.concFetch();">🞭</a> ' + '<input type="hidden" name="' + corres.input.dataset.name + '" value=\"' + corres.dataset.id + '\"/>' + corres.textContent.replace(/ *\(\d+\) *$/, '');
        label.innerHTML = html;
        corres.input.parentNode.insertBefore(label, corres.input);
        corres.input.focus();
        corres.input.suggest.hide();
        concFetch(); // refresh concordance
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
     * Initialize the destination for concordance
     * @param {HTMLDivElement} div 
     */
    function concInit(div) {
        if (!div) {
            console.log("[Elicom] No <div> for conc");
            return;
        }
        self.conc = div;
        self.form = document.forms['elicom'];
        if (!form) {
            console.log('[Elicom] No <form name="elicom"> found to pass params');
            return;
        }
        form.addEventListener('submit', (e) => {
            concFetch();
            e.preventDefault();
        });
        concFetch();
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

        input.addEventListener('click', corresFetch);
        input.addEventListener('input', corresFetch);
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
        suggestInit: suggestInit,
        concInit: concInit,
        concFetch: concFetch,
    }
}();

const inputs = document.querySelectorAll("input.multiple[data-url]");
for (let i = 0; i < inputs.length; i++) {
    Elicom.suggestInit(inputs[i]);
}
Elicom.concInit(document.getElementById('conc'));