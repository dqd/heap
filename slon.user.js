// ==UserScript==
// @name        Slon
// @version     2011-08-24
// @description Upozornění na nové rezervace v autoškole Slon.
// @namespace   slon
// @include     http://ridicembezobav.cz/planning/schedule.php*
// @include     http://*.ridicembezobav.cz/planning/schedule.php*
// ==/UserScript==

var tables = document.getElementsByTagName('table');

for (var i = 0; i < tables.length; i++) {
    if (tables[i].innerHTML.indexOf('blankOver(this)') != -1 && tables[i].innerHTML.indexOf('Pavel Dvořák') == -1) {
        alert('Volné místo.');
        break;
    }
}

setTimeout(function() {location.reload(true);}, 60000 + Math.round(Math.random() * 100000));
