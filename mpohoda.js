en_companies = [
    'Stream.io, Inc.',
    'Stream.io B.V.',
    'Hotjar Ltd',
    'Collibra Czech s.r.o.',
    'Social Sweethearts GmbH'
];
$.each($('#tblMain table > tbody > tr'), function(i, tr) {
    let uuid = $(tr).find('td:nth-child(2) > a').attr('href').slice(9);
    let company = $.trim($(tr).find('td:nth-child(5)').text());
    setTimeout(function() {
        window.open(
            'https://app.mpohoda.cz/pdf/issuedinvoice/issuedinvoice/' + uuid + (en_companies.includes(company) ? '?language=English' : ''),
            '_blank'
        );
    }, i * 1000)
});
