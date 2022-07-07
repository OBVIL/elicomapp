'use strict';

/**
 * Toolkit for some ajax hacks
 */
const Ajix = function() {
    const EOF = '\u000A';
    /**
     * Get URL and send line by line to a callback function.
     * “Line” separator could be configured with any string,
     * this allow to load multiline html chunks 
     * 
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
     * 
     * @param {*} url 
     * @param {*} callback 
     */
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
     * Send query to populate concordance
     * @param {*} id 
     * @param {*} form 
     * @param {*} url 
     * @param {*} append 
     * @returns 
     */
    function divLoad(id, form, url = null, append = false) {
        const div = document.getElementById(id);
        if (!div) { // no pb, it’s another kind of page
            return;
        }
        if (div.loading) return; // still loading
        if (!url && !div.dataset.url) {
            console.log('[Elicom] @data-url required <div id="' + id + '" data-url="data/conc">');
        }
        if (!url) url = div.dataset.url;
        if (form) url += "?" + pars(form);
        div.loading = true;
        if (!append) {
            div.innerText = '';
        }
        Ajix.loadLines(url, function(html) {
            insLine(div, html);
        }, '&#10;');
    }

    function blob2form(thing) {
        if (typeof thing === 'string') {
            let form = document.forms[thing];
            if (!form) form = document.getElementById(thing);
            // check if it is form ?
            return form;
        }
        return thing;
    }

    /**
     * Get form values as url pars
     */
    function pars(form, ...include) {
        form = blob2form(form);
        if (!form) return "";
        const formData = new FormData(form);
        // delete empty values, be careful, deletion will modify iterator
        const keys = Array.from(formData.keys());
        for (const key of keys) {
            if (include.length > 0 && !include.find(k => k === key)) {
                formData.delete(key);
            }
            if (!formData.get(key)) {
                formData.delete(key);
            }
        }
        return new URLSearchParams(formData);
    }

    /**
     * Check if at least on par is not empty
     * @param {*} id 
     * @param  {...any} include 
     * @returns 
     */
    function hasPar(form, ...include) {
        form = blob2form(form);
        if (include.length < 1) return null;
        const formData = new FormData(form);
        for (const name of include) {
            for (const value of formData.getAll(name)) {
                if (value) return true;
            }
        }
        return false;
    }
    /**
     * For event.target, get first element of name
     * @param {*} el 
     * @param {*} name 
     * @returns 
     */
    function selfOrAncestor(el, name) {
        while (el.tagName.toLowerCase() != name) {
            el = el.parentNode;
            if (!el) return false;
            let tag = el.tagName.toLowerCase();
            if (tag == 'div' || tag == 'nav' || tag == 'body') return false;
        }
        return el;
    }

    return {
        divLoad: divLoad,
        blob2form: blob2form,
        hasPar: hasPar,
        insLine: insLine,
        loadLines: loadLines,
        loadJson: loadJson,
        pars: pars,
        selfOrAncestor: selfOrAncestor,
    }

}();

const Timeplot = function() {
    /**
     * Init a timeplot
     * @param {} id 
     * @returns 
     */
    function init(timeplot, form) {
        if (typeof thing === 'string') timeplot = document.getElementById(t);
        if (!timeplot) return;
        timeplot.style.position = 'relative'; // ensure
        timeplot.form = form;
        const min = parseInt(timeplot.dataset.min, 10);
        if (isNaN(min)) console.log('[Timeplot] id="' + id + '", a min value is required, ex: data-min="1754"');
        const max = parseInt(timeplot.dataset.max, 10);
        if (isNaN(max)) console.log('[Timeplot] id="' + id + '", a max value is required, ex: data-max="1787"');
        if (isNaN(min) || isNaN(max)) return;
        const canvas = timeplot.querySelector("canvas");
        if (canvas) {
            timeplot.canvas = canvas;
            canvas.timeplot = timeplot;
            canvas.form = form;
            canvas.min = min;
            canvas.max = max;
            canvasInit(canvas);
            // canvas.load(); // no need here, should be done by global update
        }
        // get cursors
        let els = timeplot.querySelectorAll(".cursor");
        if (els.length == 2) {
            els[0].right = els[1];
            els[1].left = els[0];
            for (let i = 0; i < 2; i++) {
                els[i].timeplot = timeplot;
                els[i].canvas = canvas;
                els[i].addEventListener('mousedown', cursorClick);
                els[i].input = els[i].querySelector("input");
                els[i].input.addEventListener('change', cursorChange);
                els[i].min = min;
                els[i].max = max;
            }
            cursorMove(els[0]); // needs els[1] set
            cursorMove(els[1]);
        }

    }

    /**
     * Update interface
     */
    function update() {
        Elicom.update();
    }

    /**
     * 
     * @param {*} canvas 
     * @param {*} min 
     * @param {*} max 
     */
    function canvasInit(canvas) {
        if (!canvas) return;
        const min = canvas.min;
        const max = canvas.max;
        const tooltip = document.createElement("div");
        tooltip.classList.add('tooltip');
        tooltip.style.position = 'absolute';
        tooltip.style.visibility = 'hidden';
        canvas.parentElement.insertBefore(tooltip, canvas);
        canvas.tooltip = tooltip;
        canvas.addEventListener('mouseout', (e) => {
            tooltip.style.visibility = 'hidden';
        });
        canvas.addEventListener('click', canvasClick);
        canvas.addEventListener('mousemove', canvasMouse);
        canvas.addEventListener('mouseover', canvasMouse);
        canvas.load = canvasLoad;
    }


    /**
     * when mouse down on element attach mouse move and mouse up for document
     * so that if mouse goes outside element still drags.
     * Limit to timeplot is not efficient.
     */
    function cursorClick(e) {
        // let click in the input of the cursor
        let input = Ajix.selfOrAncestor(e.target, 'input');
        if (input) return;
        const cursor = e.currentTarget;
        e.preventDefault();
        cursor.oldX = e.clientX;
        const timeplot = cursor.parentNode;
        document.timeplot = timeplot;
        document.cursor = cursor;
        document.onmouseup = cursorDrop;
        document.onmousemove = cursorDrag;
    }

    /**
     * Drag
     * @param {*} e 
     */
    function cursorDrag(e) {
        const cursor = e.currentTarget.cursor;
        e.preventDefault();
        let newX = cursor.oldX - e.clientX; // to calculate how much we have moved
        cursor.oldX = e.clientX; // store current value to use for next move
        let left = cursor.offsetLeft - newX;
        let limit;
        let x; // get position on which calculate year
        // left element, has right
        if (cursor.right) {
            limit = -cursor.offsetWidth;
            if (left < limit) left = limit;
            limit = cursor.timeplot.offsetWidth - cursor.offsetWidth;
            if (left > limit) left = limit;
            limit = left + cursor.offsetWidth;
            if (cursor.right.offsetLeft < limit) {
                cursor.right.style.left = limit + 'px';
                cursorValue(cursor.right);
            }

        } else if (cursor.left) {
            limit = 0;
            if (left < limit) left = limit;
            limit = cursor.timeplot.offsetWidth;
            if (left > limit) left = limit;
            limit = left - cursor.left.offsetWidth;
            if (cursor.left.offsetLeft > limit) {
                cursor.left.style.left = limit + 'px';
                cursorValue(cursor.left);
            }
        }
        cursor.style.left = left + "px"; // update left position
        cursorValue(cursor);
    }

    /**
     * Set a value of cursor by position (on drag)
     * @param {*} cursor 
     * @returns 
     */
    function cursorValue(cursor) {
        if (!cursor.input) return;
        let x;
        if (cursor.right) {
            x = cursor.offsetLeft + cursor.offsetWidth;
        } else if (cursor.left) {
            x = cursor.offsetLeft;
        }
        cursor.input.value = x2year(cursor.canvas, x);
    }

    /**
     * User change Cursor value by hand
     * @param {*} e 
     * @returns 
     */
    function cursorChange(e) {
        const cursor = e.currentTarget.parentElement;
        cursorMove(cursor);
        update();
    }
    /**
     * Stop the drag handler
     * @param {*} e 
     */
    function cursorDrop(e) {
        document.onmouseup = null;
        document.onmousemove = null;
        update();
    }

    /**
     * Move a cusror by it’s value
     */
    function cursorMove(cursor) {
        let year = parseInt(cursor.input.value, 10);
        let left;
        if (cursor.right) {
            if (isNaN(year) || year < cursor.min) {
                year = cursor.min;
                cursor.input.value = year;
            }
            let limit = parseInt(cursor.right.input.value, 10);
            if (isNaN(limit) || limit > cursor.max) limit = cursor.max;
            if (year > limit) {
                year = limit;
                cursor.input.value = year;
            }
            left = year2x(cursor.canvas, year) - cursor.offsetWidth;

        } else if (cursor.left) {
            if (isNaN(year) || year > cursor.max) {
                year = cursor.max;
                cursor.input.value = year;
            }
            let limit = parseInt(cursor.left.input.value, 10);
            if (isNaN(limit) || limit < cursor.min) limit = cursor.min;
            if (year < limit) {
                year = limit;
                cursor.input.value = year;
            }
            left = year2x(cursor.canvas, year + 0.99);
        }
        cursor.style.left = left + 'px';

    }

    /**
     * Infer a year from a position on the timeplot
     * @param {*} canvas 
     * @param {*} x 
     * @returns 
     */
    function x2year(canvas, x) {
        if (!canvas) return '';
        const min = canvas.min;
        const max = canvas.max;
        const year = min + Math.floor((max - min + 1) * x / canvas.offsetWidth);
        return year;
    }

    /**
     * Infer a position on the timeplot from a year 
     * @param {*} canvas 
     * @param {*} year 
     * @returns 
     */
    function year2x(canvas, year) {
        if (!canvas) return '';
        const min = canvas.min;
        const max = canvas.max;
        const span = (max - min + 1);
        const x = canvas.offsetWidth * (year - min) / span;
        return x;
    }

    /**
     * Hyper specific 
     * @param {*} e 
     * @returns 
     */
    function canvasClick(e) {
        const canvas = e.currentTarget;
        const year = x2year(canvas, e.offsetX);
        const form = canvas.form;
        const conc = document.getElementById('conc');
        const formData = new FormData(form);
        formData.set('year1', year);
        if (conc.loading) return;
        conc.loading = true;
        conc.innerText = '';
        const url = conc.dataset.url + '?' + new URLSearchParams(formData);
        Ajix.loadLines(url, function(html) {
            Ajix.insLine(conc, html);
        }, '&#10;');
        // conc.scrollIntoView({ behavior: "smooth", block: "start" });
    }

    /**
     * 
     * @param {*} e 
     */
    function canvasMouse(e) {
        const canvas = e.currentTarget;
        const x = e.offsetX;
        const width = canvas.offsetWidth;
        const year = x2year(canvas, x);
        const tooltip = canvas.tooltip;
        tooltip.innerHTML = year;
        tooltip.style.visibility = "visible";
        if (width - x > tooltip.offsetWidth * 1.2) {
            tooltip.classList.remove('right');
            tooltip.style.right = '';
            tooltip.style.left = x + 'px';
        } else {
            tooltip.classList.add('right');
            tooltip.style.left = '';
            tooltip.style.right = (width - x) + 'px';
        }
    }




    /**
     * Load canvas with segments
     */

    function canvasLoad() {
        const canvas = this;
        const ctx = canvas.getContext('2d');
        const width = canvas.width;
        const height = canvas.height;
        // clean
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        const url = canvas.dataset.url + "?" + Ajix.pars(canvas.form);
        const max = canvas.max;
        const min = canvas.min;
        const span = max - min + 1;
        let hits;
        let n = -1;

        Ajix.loadLines(url, function(line) {
            if (!line) return;
            if (!line.trim()) return;
            n++;
            if (n == 0) {
                hits = parseInt(line);
                if (hits > 10000) {
                    ctx.strokeStyle = 'rgba(0, 0, 64, 0.1)';
                    ctx.lineWidth = 0.5;
                } else if (hits > 5000) {
                    ctx.strokeStyle = 'rgba(0, 0, 64, 0.2)';
                    ctx.lineWidth = 0.5;
                } else if (hits > 100) {
                    ctx.strokeStyle = 'rgba(0, 0, 64, 0.5)';
                    ctx.lineWidth = 1;
                } else {
                    ctx.strokeStyle = 'rgba(0, 0, 64, 0.8)';
                    ctx.lineWidth = 2;
                }
                const meta = document.querySelector("form .meta");
                if (!meta) return;
                meta.innerHTML = hits + " lettres ";
                return;
            }
            let x = width * (date2float(line) - min) / span;
            ctx.beginPath();
            ctx.moveTo(x, 0);
            ctx.lineTo(x, height);
            ctx.closePath();
            ctx.stroke();

        });

    }

    function date2float(date) {
        const months = [0, 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
        let year = parseInt(date.substr(0, 4), 10);
        let days = 0;
        let m = parseInt(date.substr(5, 2), 10);
        if (!m) return year;
        let d = parseInt(date.substr(8, 2), 10);
        if (isNaN(d)) d = 0;
        else if (d > 31) d = 30;
        else d = d - 1;
        let day = months[m] + d;
        return year + (day / 365);
    }



    return {
        init: init,
    }
}();

const Elicom = function() {
    /** Id of a form with params to send for queries like conc */
    var form = false;
    /** Register for update */
    var timeplot;

    function setTimeplot(div) {
        timeplot = div;
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
        if (
            typeof data.text === 'undefined' ||
            typeof data.id === 'undefined' ||
            data.text === null ||
            data.text === '' ||
            data.id === null ||
            data.id === ''
        ) {
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
        corres.dataset.value = data.id;
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
        Ajix.loadLines(url, function(json) {
            corresAppend(suggest, json);
        });
    }

    /**
     * Update interface with data
     */
    function update(include = "", exclude = "") {
        const operations = {
            conc: function() {
                Ajix.divLoad('conc', form)
            },
            timeplot: function() {
                if (!timeplot) return;
                else timeplot.canvas.load();
            },
            biject: biject,
            eliforms: function() {
                Ajix.divLoad('eliforms', form);
            },
            url: urlUp,
        }
        let incs = [];
        if (include) incs = include.split(/[,.\s]+/);
        let excs = [];
        if (exclude) excs = exclude.split(/[,.\s]+/);
        for (const op in operations) {
            if (incs.length > 0 && !incs.includes(op)) continue;
            if (excs.length > 0 && excs.includes(op)) continue;
            operations[op]();
        }
    }

    function urlUp() {
        const url = new URL(window.location);
        url.search = Ajix.pars(form);
        window.history.pushState({}, '', url);
    }

    /**
     * Delete an hidden field
     * @param {Event} e 
     */
    function inputDel(e) {
        const label = e.currentTarget;
        label.parentNode.removeChild(label);
        update();
    }

    /**
     * Push a value for a correspondant
     * @param {Event} e 
     */
    function corresPush(e) {
        const corres = e.currentTarget;
        const name = corres.input.id;
        const value = corres.dataset.value;
        const label = corres.textContent.replace(/ *\(\d+\) *$/, '');
        corresIns(name, value, label);
        corres.input.focus();
        corres.input.suggest.hide();
    }

    /**
     * Insert a corres field
     * @param {*} name 
     * @param {*} id 
     * @param {*} label 
     * @param {*} point 
     */
    function corresIns(name, value, label) {
        // point from where insert before the field
        const point = document.getElementById(name);
        if (!point) {
            console.log("[Elicom] suggest insert, source input not found for @id=" + name);
            return;
        }

        const el = document.createElement("label");
        el.addEventListener('click', inputDel);
        el.className = 'corres';
        el.title = label;
        const a = document.createElement("a");
        a.innerText = '🞭';
        a.className = 'inputDel';
        el.appendChild(a);
        const input = document.createElement("input");
        input.name = name;
        input.type = 'hidden';
        input.value = value;
        el.appendChild(input);
        el.appendChild(document.createTextNode(label));
        // hack
        if (name == 'sender') {
            point.parentNode.insertBefore(el, point.nextElementSibling);
        } else {
            point.parentNode.insertBefore(el, point);
        }
        update(); // update interface
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
    function init(id) {
        let _form = document.forms[id];
        if (!_form) _form = document.getElementById(id);
        if (!_form) return;
        form = id;
        _form.addEventListener('submit', (e) => {
            update();
            e.preventDefault();
        });
        if (_form.clear) {
            _form.clear.addEventListener('click', (e) => {
                _form.q.value = '';
                update();
                e.preventDefault();
            });
        }
    }
    /**
     * Click a word and update form
     * @param {*} links 
     * @param {*} conc 
     * @returns 
     */
    function words(links, conc) {
        const div = document.getElementById(links);
        if (!div) return;
        div.addEventListener('click', function(e) {
            let a = Ajix.selfOrAncestor(e.target, 'a');
            if (!a) return;
            document.forms[form].q.value = a.innerText;
            Elicom.update();
        });
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
        const pars = Ajix.pars(form);
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
     * Draw a biject graph, according to form param
     */
    function biject(id = 'biject') {
        const cont = document.getElementById(id);
        if (!cont) return;
        let url = cont.dataset.url;
        let els;
        els = cont.getElementsByClassName("senders");
        if (els.length != 1) return;
        const senders = els[0];
        els = cont.getElementsByClassName("receivers");
        if (els.length != 1) return;
        const receivers = els[0];
        els = cont.getElementsByClassName("relations");
        if (els.length != 1) return;
        const svg = els[0];
        // get data
        const pars = Ajix.pars(form);
        url += "?" + pars;
        const hmin = 16;
        const hmax = 100;
        Ajix.loadJson(url, function(json) {
            if (!json || !json.data) { // 404
                svg.innerHTML = "";
                senders.innerText = "";
                receivers.innerText = "";
                return;
            }
            const min = json.meta.min;
            const max = json.meta.max;
            senders.innerHTML = '';
            // senders.innerHTML = '<header>Expéditeurs</header>';
            corrs(senders, json.data.senders, max);
            let more = json.meta.senders;
            more = more - json.data.senders.length;
            if (more > 0) {
                const el = document.createElement('div');
                el.className = 'more';
                el.innerText = "et " + more + " autres…";
                senders.appendChild(el);
            }
            receivers.innerHTML = '';
            // receivers.innerHTML = '<header>Destinataires</header>';
            corrs(receivers, json.data.receivers, max, true);
            more = json.meta.receivers;
            more = more - json.data.receivers.length;
            if (more > 0) {
                const el = document.createElement('div');
                el.className = 'more';
                el.innerText = "et " + more + " autres…";
                receivers.appendChild(el);
            }
            edges(svg, json.data.edges, max);
        });

        function edges(svg, arr, max) {
            svg.innerHTML = "";
            const ns = svg.namespaceURI;
            const x1 = 0;
            const x2 = svg.getBoundingClientRect().width;
            for (let i = 0, length = arr.length; i < length; i++) {
                const edge = arr[i];
                let height = 0.5 + (hmax - 0.5) * (edge.count / max);
                let points = '';
                const sender = document.getElementById(edge['sender']);
                if (sender.dataset.rels < 2) {
                    var y1 = sender.offsetTop + sender.offsetHeight / 2;
                    points += x1 + "," + (y1 - height / 2) + " " + x1 + "," + (y1 + height / 2);
                } else {
                    let old = Number(sender.dataset.height);
                    if (isNaN(old)) old = 0;
                    var y1 = sender.offsetTop + old + 2 + height / 2;
                    var y = sender.offsetTop + old + 2;
                    sender.dataset.height = old + height;
                    points += x1 + "," + y + " " + x1 + "," + (y + height);
                    // points += 0 + "," + 0;
                }
                const receiver = document.getElementById(edge['receiver']);
                if (receiver.dataset.rels < 2) {
                    var y2 = receiver.offsetTop + receiver.offsetHeight / 2;
                    points += " " + x2 + "," + (y2 + height / 2) + " " + x2 + "," + (y2 - height / 2);
                } else {
                    let old = Number(receiver.dataset.height);
                    if (isNaN(old)) old = 0;
                    var y2 = receiver.offsetTop + 2 + old + height / 2;
                    var y = receiver.offsetTop + old + 2;
                    points += " " + x2 + "," + (y + height) + " " + x2 + "," + y;
                    receiver.dataset.height = old + height;
                }
                const polygon = document.createElementNS(ns, 'polygon');
                polygon.setAttribute("points", points);
                svg.appendChild(polygon);

                /*
                const line = document.createElementNS(ns, 'line');
                line.setAttribute('x1', x1);
                line.setAttribute('y1', y1);
                line.setAttribute('x2', x2);
                line.setAttribute('y2', y2);


                line.style.strokeWidth = height + 'px';
                svg.appendChild(line);
                */
            }
        }

        function corrs(div, arr, max, right = false) {
            for (let i = 0, length = arr.length; i < length; i++) {
                const corr = arr[i];
                const el = document.createElement('div');
                el.className = "corr";
                el.id = corr.id;
                let html = '<span>';
                // do not displaying counting, it’s visible edges only
                // if (!right) html += 'de ';
                // if (right) html += '<small class="count">(' + corr.count + ') </small>';
                // if (right) html += 'à ';
                html += corr.label;
                // if (!right) 
                html += ' <small class="count">(' + corr.freq + ')</small>';
                html += '</span>';
                el.innerHTML = html;
                let height = hmax * (corr.count / max) + 4;
                if (height > hmin) {
                    el.style.height = height + 'px';
                }
                el.dataset.rels = corr.rels;
                // Motasem don’t like 
                // el.addEventListener('click', corrIns);
                el.dataset.corres = corr.corres;
                if (right) el.dataset.name = 'corres2';
                else el.dataset.name = 'corres1';
                div.appendChild(el);
            }
        }

        function corrIns(e) {
            const div = e.currentTarget;
            const name = div.dataset.name;
            const value = div.dataset.corres;
            const label = div.textContent.replace(/ *\(\d+\) */, '');
            corresIns(name, value, label);
        }
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
        if (!input.id) {
            console.log("[Elicom] No @id, required to create params\n" + input);
            return;
        }
        input.autocomplete = 'off';
        // create suggest
        const suggest = document.createElement("div");
        suggest.className = "suggest " + input.id;
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
        biject: biject,
        graphInit: graphInit,
        graphUp: graphUp,
        init: init,
        inputDel: inputDel,
        setTimeplot: setTimeplot,
        update: update,
        urlUp: urlUp,
        suggestInit: suggestInit,
        words: words,
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

        Elicom.update();
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
    const form = document.forms[0];
    // Build the timeplot
    const timeplot = document.getElementById('timeplot');
    Timeplot.init(timeplot, form);
    Elicom.init('elicom'); // form is required
    // set timeplot
    Elicom.setTimeplot(timeplot);
    Elicom.words('eliforms', 'conc');
    window.addEventListener('resize', function(e) {
        Elicom.biject();
        Timeplot.init(timeplot, form);
    });
    // Elicom.pushdiv(document.getElementById('table'));
    // Elicom.graphInit(document.getElementById('graph'));
    const inputs = document.querySelectorAll("input.multiple[data-url]");
    const conc = document.getElementById('conc');
    if (conc) {
        const name = 'letter';
        // window.open('', name).close();
        conc.tab = null;
        conc.addEventListener('click', function(e) {
            let a = Ajix.selfOrAncestor(e.target, 'a');
            if (!a) return;
            if (!a.href) return;
            console.log(a);
            e.preventDefault();
            e.stopPropagation();
            if (!conc.tab || conc.tab) {
                conc.tab = window.open(a.href, name);
            } else {
                conc.tab.location = a.href;
            }
        });
    }
    for (let i = 0; i < inputs.length; i++) {
        Elicom.suggestInit(inputs[i]);
    }
    // corres fields to animate
    for (var item of document.querySelectorAll("label.corres")) {
        item.addEventListener('click', Elicom.inputDel);
    }
    Elicom.update(null, 'url'); // no entry in history
    if (form && form['cat']) {
        const select = form['cat'];
        select.addEventListener("change", function(e) {
            Elicom.update("eliforms");
        });

        /*
        const key = "elicom.cat";
        // on load last value
        window.addEventListener("load", function(e) {
            const value = localStorage.getItem(id);
            if (value) {
                select.value = value;
                show(value);
            }
        })

        */

    }
})();